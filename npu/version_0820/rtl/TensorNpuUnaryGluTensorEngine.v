`timescale 1ns/1ps

// SPDX-License-Identifier: MIT
//
// TENSOR_NPU_UNARY_GLU_F32_RNE_V1 的 LANES=1 全 tensor reference engine。
// 阶段1/2a--2e与九项RTL topology推导见：
// tmp/logs/unary-glu-tensor-engine/rtl-derivation.md
//
// 本模块先capture完整tensor并完成finite preflight，再独占一个
// TensorNpuUnaryGluElement逐项执行。两个result bank与2-entry order FIFO
// 只解决提交/输出重叠，不复制source owner或scalar datapath。
module TensorNpuUnaryGluTensorEngine #(
    parameter integer MAX_ELEMS = 6144,
    parameter integer ELEMENT_TIMEOUT_CYCLES = 256
) (
    input  wire        clk_i,
    input  wire        rst_i,

    input  wire        cmd_valid_i,
    output wire        cmd_ready_o,
    input  wire [2:0]  cmd_opcode_i,
    input  wire [12:0] cmd_length_i,
    input  wire [7:0]  cmd_tag_i,
    output wire        busy_o,

    input  wire        in_valid_i,
    output wire        in_ready_o,
    input  wire [31:0] in_src0_bits_i,
    input  wire [31:0] in_src1_bits_i,

    output wire        out_valid_o,
    input  wire        out_ready_i,
    output wire        out_sop_o,
    output wire        out_last_o,
    output wire        out_keep_o,
    output wire [31:0] out_result_bits_o,
    output wire [4:0]  out_flags_o,
    output wire [12:0] out_elem_index_o,

    output wire [7:0]  out_tag_o,
    output wire [2:0]  out_opcode_o,
    output wire [12:0] out_length_o,
    output wire        out_error_o,
    output wire [3:0]  out_error_code_o,
    output wire [63:0] out_active_cycles_o,

    output wire [12:0] out_capture_count_o,
    output wire [12:0] out_scalar_launch_count_o,
    output wire [12:0] out_scalar_terminal_count_o,
    output wire [12:0] out_success_result_count_o,
    output wire [4:0]  out_child_call_mask_o,
    output wire [12:0] out_exp_req_count_o,
    output wire [12:0] out_add_req_count_o,
    output wire [12:0] out_div_req_count_o,
    output wire [12:0] out_log_req_count_o,
    output wire [12:0] out_mul_req_count_o,
    output wire [12:0] out_bypass_count_o,
    output wire [4:0]  out_tensor_flags_or_o,
    output wire        out_fail_elem_valid_o,
    output wire [12:0] out_fail_elem_index_o
);

    localparam [2:0] OP_SOFTPLUS = 3'd1;
    localparam [2:0] OP_SWIGLU   = 3'd3;

    localparam [3:0] ERR_OK          = 4'd0;
    localparam [3:0] ERR_UNSUPPORTED = 4'd1;
    localparam [3:0] ERR_PROTOCOL    = 4'd4;

    localparam [2:0] CTRL_IDLE      = 3'd0;
    localparam [2:0] CTRL_CAPTURE   = 3'd1;
    localparam [2:0] CTRL_EXEC_REQ  = 3'd2;
    localparam [2:0] CTRL_EXEC_WAIT = 3'd3;
    localparam [2:0] CTRL_QUARANTINE = 3'd4;

    localparam [2:0] BANK_FREE      = 3'd0;
    localparam [2:0] BANK_FILL      = 3'd1;
    localparam [2:0] BANK_READY_OK  = 3'd2;
    localparam [2:0] BANK_DRAIN     = 3'd3;
    localparam [2:0] BANK_READY_ERR = 3'd4;

    // 非法参数配置不能形成0/负深度数组，也不能启动capture/scalar。
    localparam integer SAFE_STORAGE_ELEMS =
        ((MAX_ELEMS >= 1) && (MAX_ELEMS <= 6144)) ? MAX_ELEMS : 1;
    localparam [0:0] PARAM_VALID =
        (MAX_ELEMS >= 1) && (MAX_ELEMS <= 6144) &&
        (ELEMENT_TIMEOUT_CYCLES > 0);
    localparam [31:0] MAX_ELEMS_U32 = MAX_ELEMS;

    // 小型纯组合predicate综合为8-bit exponent比较器。
    function external_nonfinite;
        input [7:0] exponent;
        begin
            external_nonfinite = (exponent == 8'hff);
        end
    endfunction

    // ------------------------------------------------------------------
    // Source staging、唯一owner及controller work registers。
    // ------------------------------------------------------------------
    reg [31:0] src0_mem_q [0:SAFE_STORAGE_ELEMS-1];
    reg [31:0] src1_mem_q [0:SAFE_STORAGE_ELEMS-1];

    reg [2:0]  ctrl_state_q;
    reg        ctrl_state_valid;
    reg        source_owner_valid_q;
    reg        active_bank_q;
    reg [2:0]  active_opcode_q;
    reg [12:0] active_length_q;
    reg [63:0] start_ts_q;
    reg [63:0] wall_ts_q;

    reg [12:0] capture_count_q;
    reg [12:0] exec_index_q;
    reg        external_bad_seen_q;
    reg [12:0] external_bad_index_q;

    reg [12:0] work_scalar_launch_count_q;
    reg [12:0] work_scalar_terminal_count_q;
    reg [12:0] work_success_result_count_q;
    reg [4:0]  work_child_call_mask_q;
    reg [12:0] work_exp_req_count_q;
    reg [12:0] work_add_req_count_q;
    reg [12:0] work_div_req_count_q;
    reg [12:0] work_log_req_count_q;
    reg [12:0] work_mul_req_count_q;
    reg [12:0] work_bypass_count_q;
    reg [4:0]  work_tensor_flags_or_q;

    // ------------------------------------------------------------------
    // 两份result memory与bank-local terminal metadata。
    // ------------------------------------------------------------------
    reg [31:0] bank0_result_mem_q [0:SAFE_STORAGE_ELEMS-1];
    reg [31:0] bank1_result_mem_q [0:SAFE_STORAGE_ELEMS-1];
    reg [4:0]  bank0_flags_mem_q  [0:SAFE_STORAGE_ELEMS-1];
    reg [4:0]  bank1_flags_mem_q  [0:SAFE_STORAGE_ELEMS-1];

    reg [2:0]  bank0_state_q;
    reg [7:0]  bank0_tag_q;
    reg [2:0]  bank0_opcode_q;
    reg [12:0] bank0_length_q;
    reg [3:0]  bank0_error_code_q;
    reg [63:0] bank0_active_cycles_q;
    reg [12:0] bank0_capture_count_q;
    reg [12:0] bank0_scalar_launch_count_q;
    reg [12:0] bank0_scalar_terminal_count_q;
    reg [12:0] bank0_success_result_count_q;
    reg [4:0]  bank0_child_call_mask_q;
    reg [12:0] bank0_exp_req_count_q;
    reg [12:0] bank0_add_req_count_q;
    reg [12:0] bank0_div_req_count_q;
    reg [12:0] bank0_log_req_count_q;
    reg [12:0] bank0_mul_req_count_q;
    reg [12:0] bank0_bypass_count_q;
    reg [4:0]  bank0_tensor_flags_or_q;
    reg        bank0_fail_elem_valid_q;
    reg [12:0] bank0_fail_elem_index_q;
    reg [12:0] bank0_out_index_q;

    reg [2:0]  bank1_state_q;
    reg [7:0]  bank1_tag_q;
    reg [2:0]  bank1_opcode_q;
    reg [12:0] bank1_length_q;
    reg [3:0]  bank1_error_code_q;
    reg [63:0] bank1_active_cycles_q;
    reg [12:0] bank1_capture_count_q;
    reg [12:0] bank1_scalar_launch_count_q;
    reg [12:0] bank1_scalar_terminal_count_q;
    reg [12:0] bank1_success_result_count_q;
    reg [4:0]  bank1_child_call_mask_q;
    reg [12:0] bank1_exp_req_count_q;
    reg [12:0] bank1_add_req_count_q;
    reg [12:0] bank1_div_req_count_q;
    reg [12:0] bank1_log_req_count_q;
    reg [12:0] bank1_mul_req_count_q;
    reg [12:0] bank1_bypass_count_q;
    reg [4:0]  bank1_tensor_flags_or_q;
    reg        bank1_fail_elem_valid_q;
    reg [12:0] bank1_fail_elem_index_q;
    reg [12:0] bank1_out_index_q;

    // 2-entry FIFO只保存bank id；pointer均为1 bit。
    reg order_fifo_q [0:1];
    reg fifo_rd_ptr_q;
    reg fifo_wr_ptr_q;
    reg [1:0] fifo_count_q;

    wire bank0_free = (bank0_state_q == BANK_FREE);
    wire bank1_free = (bank1_state_q == BANK_FREE);
    wire exists_free_bank = bank0_free || bank1_free;
    wire alloc_bank = bank0_free ? 1'b0 : 1'b1;

    wire command_length_valid =
        (cmd_length_i != 13'b0) &&
        ({19'b0, cmd_length_i} <= MAX_ELEMS_U32);
    wire command_is_valid =
        PARAM_VALID && (cmd_opcode_i <= OP_SWIGLU) && command_length_valid;

    assign cmd_ready_o =
        !rst_i && (ctrl_state_q == CTRL_IDLE) &&
        !source_owner_valid_q && (fifo_count_q < 2'd2) && exists_free_bank;
    wire cmd_fire = cmd_valid_i && cmd_ready_o;

    // 非法parent编码不是普通idle：立即撤销credit并局部reset resident
    // scalar，随后保留一个完整QUARANTINE active edge，才重新开放命令。
    always @(*) begin
        ctrl_state_valid = 1'b1;
        case (ctrl_state_q)
            CTRL_IDLE, CTRL_CAPTURE, CTRL_EXEC_REQ, CTRL_EXEC_WAIT,
            CTRL_QUARANTINE: ctrl_state_valid = 1'b1;
            default: ctrl_state_valid = 1'b0;
        endcase
    end

    wire controller_state_illegal = !ctrl_state_valid;
    wire parent_element_rst =
        rst_i || controller_state_illegal ||
        (ctrl_state_q == CTRL_QUARANTINE);

    assign busy_o = !rst_i && (fifo_count_q != 2'd0);

    assign in_ready_o =
        !rst_i && source_owner_valid_q && (ctrl_state_q == CTRL_CAPTURE);
    wire in_fire = in_valid_i && in_ready_o;
    wire [12:0] capture_count_next = capture_count_q + 13'd1;
    wire capture_bad_this =
        external_nonfinite(in_src0_bits_i[30:23]) ||
        ((active_opcode_q == OP_SWIGLU) &&
         external_nonfinite(in_src1_bits_i[30:23]));
    wire capture_bad_next = external_bad_seen_q || capture_bad_this;
    wire capture_last_fire =
        in_fire && (capture_count_next == active_length_q);
    wire capture_bad_terminal = capture_last_fire && capture_bad_next;

    // ------------------------------------------------------------------
    // 唯一真实scalar engine。REQ state保持memory payload，WAIT state持续给credit。
    // ------------------------------------------------------------------
    wire        element_req_valid;
    wire        element_req_ready;
    wire        element_rsp_valid;
    wire        element_rsp_ready;
    wire [31:0] element_result_bits;
    wire [4:0]  element_flags;
    wire        element_error;
    wire [3:0]  element_error_code;
    wire [4:0]  element_child_call_mask;
    /* verilator lint_off UNUSEDSIGNAL */
    wire [31:0] element_active_cycles_unused;
    /* verilator lint_on UNUSEDSIGNAL */

    assign element_req_valid =
        !parent_element_rst && source_owner_valid_q &&
        (ctrl_state_q == CTRL_EXEC_REQ);
    assign element_rsp_ready =
        !parent_element_rst && source_owner_valid_q &&
        (ctrl_state_q == CTRL_EXEC_WAIT);

    TensorNpuUnaryGluElement #(
        .COMMAND_TIMEOUT_CYCLES(ELEMENT_TIMEOUT_CYCLES)
    ) u_element (
        .clk_i          (clk_i),
        .rst_i          (parent_element_rst),
        .req_valid_i    (element_req_valid),
        .req_ready_o    (element_req_ready),
        .opcode_i       (active_opcode_q),
        .src0_bits_i    (src0_mem_q[exec_index_q]),
        .src1_bits_i    (src1_mem_q[exec_index_q]),
        .rsp_valid_o    (element_rsp_valid),
        .rsp_ready_i    (element_rsp_ready),
        .result_bits_o  (element_result_bits),
        .flags_o        (element_flags),
        .error_o        (element_error),
        .error_code_o   (element_error_code),
        .child_call_mask_o(element_child_call_mask),
        .active_cycles_o(element_active_cycles_unused)
    );

    wire scalar_req_fire = element_req_valid && element_req_ready;
    wire scalar_rsp_fire = element_rsp_valid && element_rsp_ready;
    wire scalar_success_last =
        scalar_rsp_fire && !element_error &&
        ((exec_index_q + 13'd1) == active_length_q);
    wire scalar_error_terminal = scalar_rsp_fire && element_error;

    wire controller_fault_terminal =
        source_owner_valid_q && controller_state_illegal;
    wire tensor_terminal =
        capture_bad_terminal || scalar_success_last ||
        scalar_error_terminal || controller_fault_terminal;
    wire tensor_terminal_ok = scalar_success_last;

    wire [3:0] tensor_terminal_error_code =
        capture_bad_terminal ? ERR_UNSUPPORTED :
        scalar_error_terminal ?
            ((element_error_code == ERR_OK) ? ERR_PROTOCOL : element_error_code) :
        controller_fault_terminal ? ERR_PROTOCOL : ERR_OK;
    wire [63:0] tensor_terminal_active_cycles =
        wall_ts_q - start_ts_q + 64'd1;
    wire [12:0] tensor_terminal_capture_count =
        capture_bad_terminal ? capture_count_next : capture_count_q;
    wire [12:0] tensor_terminal_scalar_terminal_count =
        work_scalar_terminal_count_q +
        (scalar_rsp_fire ? 13'd1 : 13'd0);
    wire [12:0] tensor_terminal_success_result_count =
        work_success_result_count_q +
        (scalar_success_last ? 13'd1 : 13'd0);
    wire [4:0] tensor_terminal_child_call_mask =
        work_child_call_mask_q |
        (scalar_rsp_fire ? element_child_call_mask : 5'b0);
    wire [12:0] tensor_terminal_exp_req_count =
        work_exp_req_count_q +
        ((scalar_rsp_fire && element_child_call_mask[0]) ? 13'd1 : 13'd0);
    wire [12:0] tensor_terminal_add_req_count =
        work_add_req_count_q +
        ((scalar_rsp_fire && element_child_call_mask[1]) ? 13'd1 : 13'd0);
    wire [12:0] tensor_terminal_div_req_count =
        work_div_req_count_q +
        ((scalar_rsp_fire && element_child_call_mask[2]) ? 13'd1 : 13'd0);
    wire [12:0] tensor_terminal_log_req_count =
        work_log_req_count_q +
        ((scalar_rsp_fire && element_child_call_mask[3]) ? 13'd1 : 13'd0);
    wire [12:0] tensor_terminal_mul_req_count =
        work_mul_req_count_q +
        ((scalar_rsp_fire && element_child_call_mask[4]) ? 13'd1 : 13'd0);
    wire scalar_bypass_terminal =
        scalar_rsp_fire && !element_error &&
        (active_opcode_q == OP_SOFTPLUS) &&
        (element_child_call_mask == 5'b0);
    wire [12:0] tensor_terminal_bypass_count =
        work_bypass_count_q + (scalar_bypass_terminal ? 13'd1 : 13'd0);
    wire [4:0] tensor_terminal_flags_or =
        work_tensor_flags_or_q |
        ((scalar_rsp_fire && !element_error) ? element_flags : 5'b0);
    wire tensor_terminal_fail_elem_valid =
        capture_bad_terminal || scalar_error_terminal || controller_fault_terminal;
    wire [12:0] tensor_terminal_fail_elem_index =
        capture_bad_terminal ?
            (external_bad_seen_q ? external_bad_index_q : capture_count_q) :
        exec_index_q;

    // ------------------------------------------------------------------
    // FIFO head-only output mux。错误completion不读result memory。
    // ------------------------------------------------------------------
    wire fifo_head_bank = order_fifo_q[fifo_rd_ptr_q];

    reg        out_valid_r;
    reg        out_sop_r;
    reg        out_last_r;
    reg        out_keep_r;
    reg [31:0] out_result_bits_r;
    reg [4:0]  out_flags_r;
    reg [12:0] out_elem_index_r;
    reg [7:0]  out_tag_r;
    reg [2:0]  out_opcode_r;
    reg [12:0] out_length_r;
    reg        out_error_r;
    reg [3:0]  out_error_code_r;
    reg [63:0] out_active_cycles_r;
    reg [12:0] out_capture_count_r;
    reg [12:0] out_scalar_launch_count_r;
    reg [12:0] out_scalar_terminal_count_r;
    reg [12:0] out_success_result_count_r;
    reg [4:0]  out_child_call_mask_r;
    reg [12:0] out_exp_req_count_r;
    reg [12:0] out_add_req_count_r;
    reg [12:0] out_div_req_count_r;
    reg [12:0] out_log_req_count_r;
    reg [12:0] out_mul_req_count_r;
    reg [12:0] out_bypass_count_r;
    reg [4:0]  out_tensor_flags_or_r;
    reg        out_fail_elem_valid_r;
    reg [12:0] out_fail_elem_index_r;

    always @(*) begin
        out_valid_r                 = 1'b0;
        out_sop_r                   = 1'b0;
        out_last_r                  = 1'b0;
        out_keep_r                  = 1'b0;
        out_result_bits_r           = 32'b0;
        out_flags_r                 = 5'b0;
        out_elem_index_r            = 13'b0;
        out_tag_r                   = 8'b0;
        out_opcode_r                = 3'b0;
        out_length_r                = 13'b0;
        out_error_r                 = 1'b0;
        out_error_code_r            = ERR_OK;
        out_active_cycles_r         = 64'b0;
        out_capture_count_r         = 13'b0;
        out_scalar_launch_count_r   = 13'b0;
        out_scalar_terminal_count_r = 13'b0;
        out_success_result_count_r  = 13'b0;
        out_child_call_mask_r       = 5'b0;
        out_exp_req_count_r         = 13'b0;
        out_add_req_count_r         = 13'b0;
        out_div_req_count_r         = 13'b0;
        out_log_req_count_r         = 13'b0;
        out_mul_req_count_r         = 13'b0;
        out_bypass_count_r          = 13'b0;
        out_tensor_flags_or_r       = 5'b0;
        out_fail_elem_valid_r       = 1'b0;
        out_fail_elem_index_r       = 13'b0;

        if (!rst_i && (fifo_count_q != 2'd0)) begin
            if (!fifo_head_bank &&
                ((bank0_state_q == BANK_READY_OK) ||
                 (bank0_state_q == BANK_DRAIN))) begin
                out_valid_r                 = 1'b1;
                out_sop_r                   = (bank0_out_index_q == 13'd0);
                out_last_r                  =
                    ((bank0_out_index_q + 13'd1) == bank0_length_q);
                out_keep_r                  = 1'b1;
                out_result_bits_r           = bank0_result_mem_q[bank0_out_index_q];
                out_flags_r                 = bank0_flags_mem_q[bank0_out_index_q];
                out_elem_index_r            = bank0_out_index_q;
                out_tag_r                   = bank0_tag_q;
                out_opcode_r                = bank0_opcode_q;
                out_length_r                = bank0_length_q;
                out_error_r                 = 1'b0;
                out_error_code_r            = ERR_OK;
                out_active_cycles_r         = bank0_active_cycles_q;
                out_capture_count_r         = bank0_capture_count_q;
                out_scalar_launch_count_r   = bank0_scalar_launch_count_q;
                out_scalar_terminal_count_r = bank0_scalar_terminal_count_q;
                out_success_result_count_r  = bank0_success_result_count_q;
                out_child_call_mask_r       = bank0_child_call_mask_q;
                out_exp_req_count_r         = bank0_exp_req_count_q;
                out_add_req_count_r         = bank0_add_req_count_q;
                out_div_req_count_r         = bank0_div_req_count_q;
                out_log_req_count_r         = bank0_log_req_count_q;
                out_mul_req_count_r         = bank0_mul_req_count_q;
                out_bypass_count_r          = bank0_bypass_count_q;
                out_tensor_flags_or_r       = bank0_tensor_flags_or_q;
                out_fail_elem_valid_r       = bank0_fail_elem_valid_q;
                out_fail_elem_index_r       = bank0_fail_elem_index_q;
            end else if (!fifo_head_bank &&
                         (bank0_state_q == BANK_READY_ERR)) begin
                out_valid_r                 = 1'b1;
                out_sop_r                   = 1'b1;
                out_last_r                  = 1'b1;
                out_keep_r                  = 1'b0;
                out_result_bits_r           = 32'b0;
                out_flags_r                 = 5'b0;
                out_elem_index_r            = 13'b0;
                out_tag_r                   = bank0_tag_q;
                out_opcode_r                = bank0_opcode_q;
                out_length_r                = bank0_length_q;
                out_error_r                 = 1'b1;
                out_error_code_r            = bank0_error_code_q;
                out_active_cycles_r         = bank0_active_cycles_q;
                out_capture_count_r         = bank0_capture_count_q;
                out_scalar_launch_count_r   = bank0_scalar_launch_count_q;
                out_scalar_terminal_count_r = bank0_scalar_terminal_count_q;
                out_success_result_count_r  = bank0_success_result_count_q;
                out_child_call_mask_r       = bank0_child_call_mask_q;
                out_exp_req_count_r         = bank0_exp_req_count_q;
                out_add_req_count_r         = bank0_add_req_count_q;
                out_div_req_count_r         = bank0_div_req_count_q;
                out_log_req_count_r         = bank0_log_req_count_q;
                out_mul_req_count_r         = bank0_mul_req_count_q;
                out_bypass_count_r          = bank0_bypass_count_q;
                out_tensor_flags_or_r       = 5'b0;
                out_fail_elem_valid_r       = bank0_fail_elem_valid_q;
                out_fail_elem_index_r       = bank0_fail_elem_index_q;
            end else if (fifo_head_bank &&
                         ((bank1_state_q == BANK_READY_OK) ||
                          (bank1_state_q == BANK_DRAIN))) begin
                out_valid_r                 = 1'b1;
                out_sop_r                   = (bank1_out_index_q == 13'd0);
                out_last_r                  =
                    ((bank1_out_index_q + 13'd1) == bank1_length_q);
                out_keep_r                  = 1'b1;
                out_result_bits_r           = bank1_result_mem_q[bank1_out_index_q];
                out_flags_r                 = bank1_flags_mem_q[bank1_out_index_q];
                out_elem_index_r            = bank1_out_index_q;
                out_tag_r                   = bank1_tag_q;
                out_opcode_r                = bank1_opcode_q;
                out_length_r                = bank1_length_q;
                out_error_r                 = 1'b0;
                out_error_code_r            = ERR_OK;
                out_active_cycles_r         = bank1_active_cycles_q;
                out_capture_count_r         = bank1_capture_count_q;
                out_scalar_launch_count_r   = bank1_scalar_launch_count_q;
                out_scalar_terminal_count_r = bank1_scalar_terminal_count_q;
                out_success_result_count_r  = bank1_success_result_count_q;
                out_child_call_mask_r       = bank1_child_call_mask_q;
                out_exp_req_count_r         = bank1_exp_req_count_q;
                out_add_req_count_r         = bank1_add_req_count_q;
                out_div_req_count_r         = bank1_div_req_count_q;
                out_log_req_count_r         = bank1_log_req_count_q;
                out_mul_req_count_r         = bank1_mul_req_count_q;
                out_bypass_count_r          = bank1_bypass_count_q;
                out_tensor_flags_or_r       = bank1_tensor_flags_or_q;
                out_fail_elem_valid_r       = bank1_fail_elem_valid_q;
                out_fail_elem_index_r       = bank1_fail_elem_index_q;
            end else if (fifo_head_bank &&
                         (bank1_state_q == BANK_READY_ERR)) begin
                out_valid_r                 = 1'b1;
                out_sop_r                   = 1'b1;
                out_last_r                  = 1'b1;
                out_keep_r                  = 1'b0;
                out_result_bits_r           = 32'b0;
                out_flags_r                 = 5'b0;
                out_elem_index_r            = 13'b0;
                out_tag_r                   = bank1_tag_q;
                out_opcode_r                = bank1_opcode_q;
                out_length_r                = bank1_length_q;
                out_error_r                 = 1'b1;
                out_error_code_r            = bank1_error_code_q;
                out_active_cycles_r         = bank1_active_cycles_q;
                out_capture_count_r         = bank1_capture_count_q;
                out_scalar_launch_count_r   = bank1_scalar_launch_count_q;
                out_scalar_terminal_count_r = bank1_scalar_terminal_count_q;
                out_success_result_count_r  = bank1_success_result_count_q;
                out_child_call_mask_r       = bank1_child_call_mask_q;
                out_exp_req_count_r         = bank1_exp_req_count_q;
                out_add_req_count_r         = bank1_add_req_count_q;
                out_div_req_count_r         = bank1_div_req_count_q;
                out_log_req_count_r         = bank1_log_req_count_q;
                out_mul_req_count_r         = bank1_mul_req_count_q;
                out_bypass_count_r          = bank1_bypass_count_q;
                out_tensor_flags_or_r       = 5'b0;
                out_fail_elem_valid_r       = bank1_fail_elem_valid_q;
                out_fail_elem_index_r       = bank1_fail_elem_index_q;
            end
        end
    end

    assign out_valid_o                 = out_valid_r;
    assign out_sop_o                   = out_sop_r;
    assign out_last_o                  = out_last_r;
    assign out_keep_o                  = out_keep_r;
    assign out_result_bits_o           = out_result_bits_r;
    assign out_flags_o                 = out_flags_r;
    assign out_elem_index_o            = out_elem_index_r;
    assign out_tag_o                   = out_tag_r;
    assign out_opcode_o                = out_opcode_r;
    assign out_length_o                = out_length_r;
    assign out_error_o                 = out_error_r;
    assign out_error_code_o            = out_error_code_r;
    assign out_active_cycles_o         = out_active_cycles_r;
    assign out_capture_count_o         = out_capture_count_r;
    assign out_scalar_launch_count_o   = out_scalar_launch_count_r;
    assign out_scalar_terminal_count_o = out_scalar_terminal_count_r;
    assign out_success_result_count_o  = out_success_result_count_r;
    assign out_child_call_mask_o       = out_child_call_mask_r;
    assign out_exp_req_count_o         = out_exp_req_count_r;
    assign out_add_req_count_o         = out_add_req_count_r;
    assign out_div_req_count_o         = out_div_req_count_r;
    assign out_log_req_count_o         = out_log_req_count_r;
    assign out_mul_req_count_o         = out_mul_req_count_r;
    assign out_bypass_count_o          = out_bypass_count_r;
    assign out_tensor_flags_or_o       = out_tensor_flags_or_r;
    assign out_fail_elem_valid_o       = out_fail_elem_valid_r;
    assign out_fail_elem_index_o       = out_fail_elem_index_r;

    wire out_fire = out_valid_o && out_ready_i;
    wire out_pop = out_fire && out_last_o;

    // ------------------------------------------------------------------
    // 单一posedge owner。reset最高优先级；output、FIFO和active work可在不同bank并行。
    // ------------------------------------------------------------------
    always @(posedge clk_i) begin
        if (rst_i) begin
            wall_ts_q                       <= 64'b0;
            ctrl_state_q                    <= CTRL_IDLE;
            source_owner_valid_q            <= 1'b0;
            active_bank_q                   <= 1'b0;
            active_opcode_q                 <= 3'b0;
            active_length_q                 <= 13'b0;
            start_ts_q                      <= 64'b0;
            capture_count_q                 <= 13'b0;
            exec_index_q                    <= 13'b0;
            external_bad_seen_q             <= 1'b0;
            external_bad_index_q            <= 13'b0;
            work_scalar_launch_count_q      <= 13'b0;
            work_scalar_terminal_count_q    <= 13'b0;
            work_success_result_count_q     <= 13'b0;
            work_child_call_mask_q          <= 5'b0;
            work_exp_req_count_q            <= 13'b0;
            work_add_req_count_q            <= 13'b0;
            work_div_req_count_q            <= 13'b0;
            work_log_req_count_q            <= 13'b0;
            work_mul_req_count_q            <= 13'b0;
            work_bypass_count_q             <= 13'b0;
            work_tensor_flags_or_q          <= 5'b0;

            bank0_state_q                   <= BANK_FREE;
            bank0_tag_q                     <= 8'b0;
            bank0_opcode_q                  <= 3'b0;
            bank0_length_q                  <= 13'b0;
            bank0_error_code_q              <= ERR_OK;
            bank0_active_cycles_q           <= 64'b0;
            bank0_capture_count_q           <= 13'b0;
            bank0_scalar_launch_count_q     <= 13'b0;
            bank0_scalar_terminal_count_q   <= 13'b0;
            bank0_success_result_count_q    <= 13'b0;
            bank0_child_call_mask_q         <= 5'b0;
            bank0_exp_req_count_q           <= 13'b0;
            bank0_add_req_count_q           <= 13'b0;
            bank0_div_req_count_q           <= 13'b0;
            bank0_log_req_count_q           <= 13'b0;
            bank0_mul_req_count_q           <= 13'b0;
            bank0_bypass_count_q            <= 13'b0;
            bank0_tensor_flags_or_q         <= 5'b0;
            bank0_fail_elem_valid_q         <= 1'b0;
            bank0_fail_elem_index_q         <= 13'b0;
            bank0_out_index_q               <= 13'b0;

            bank1_state_q                   <= BANK_FREE;
            bank1_tag_q                     <= 8'b0;
            bank1_opcode_q                  <= 3'b0;
            bank1_length_q                  <= 13'b0;
            bank1_error_code_q              <= ERR_OK;
            bank1_active_cycles_q           <= 64'b0;
            bank1_capture_count_q           <= 13'b0;
            bank1_scalar_launch_count_q     <= 13'b0;
            bank1_scalar_terminal_count_q   <= 13'b0;
            bank1_success_result_count_q    <= 13'b0;
            bank1_child_call_mask_q         <= 5'b0;
            bank1_exp_req_count_q           <= 13'b0;
            bank1_add_req_count_q           <= 13'b0;
            bank1_div_req_count_q           <= 13'b0;
            bank1_log_req_count_q           <= 13'b0;
            bank1_mul_req_count_q           <= 13'b0;
            bank1_bypass_count_q            <= 13'b0;
            bank1_tensor_flags_or_q         <= 5'b0;
            bank1_fail_elem_valid_q         <= 1'b0;
            bank1_fail_elem_index_q         <= 13'b0;
            bank1_out_index_q               <= 13'b0;

            order_fifo_q[0]                 <= 1'b0;
            order_fifo_q[1]                 <= 1'b0;
            fifo_rd_ptr_q                   <= 1'b0;
            fifo_wr_ptr_q                   <= 1'b0;
            fifo_count_q                    <= 2'b0;
        end else begin
            wall_ts_q <= wall_ts_q + 64'd1;

            // Head output owner只在真实handshake推进；hold时所有寄存器自然保持。
            if (out_fire) begin
                if (!fifo_head_bank) begin
                    if (out_last_o) begin
                        bank0_state_q     <= BANK_FREE;
                        bank0_out_index_q <= 13'b0;
                    end else begin
                        bank0_state_q     <= BANK_DRAIN;
                        bank0_out_index_q <= bank0_out_index_q + 13'd1;
                    end
                end else begin
                    if (out_last_o) begin
                        bank1_state_q     <= BANK_FREE;
                        bank1_out_index_q <= 13'b0;
                    end else begin
                        bank1_state_q     <= BANK_DRAIN;
                        bank1_out_index_q <= bank1_out_index_q + 13'd1;
                    end
                end
            end

            // FIFO push/pop四种边界显式守恒；full时cmd_fire结构上为0。
            case ({cmd_fire, out_pop})
                2'b10: begin
                    order_fifo_q[fifo_wr_ptr_q] <= alloc_bank;
                    fifo_wr_ptr_q               <= ~fifo_wr_ptr_q;
                    fifo_count_q                <= fifo_count_q + 2'd1;
                end
                2'b01: begin
                    fifo_rd_ptr_q <= ~fifo_rd_ptr_q;
                    fifo_count_q  <= fifo_count_q - 2'd1;
                end
                2'b11: begin
                    order_fifo_q[fifo_wr_ptr_q] <= alloc_bank;
                    fifo_wr_ptr_q               <= ~fifo_wr_ptr_q;
                    fifo_rd_ptr_q               <= ~fifo_rd_ptr_q;
                    fifo_count_q                <= fifo_count_q;
                end
                default: begin
                    fifo_wr_ptr_q <= fifo_wr_ptr_q;
                    fifo_rd_ptr_q <= fifo_rd_ptr_q;
                    fifo_count_q  <= fifo_count_q;
                end
            endcase

            // command edge原子初始化bank descriptor；immediate error不获取source owner。
            if (cmd_fire) begin
                if (!alloc_bank) begin
                    bank0_state_q                 <=
                        command_is_valid ? BANK_FILL : BANK_READY_ERR;
                    bank0_tag_q                   <= cmd_tag_i;
                    bank0_opcode_q                <= cmd_opcode_i;
                    bank0_length_q                <= cmd_length_i;
                    bank0_error_code_q            <=
                        command_is_valid ? ERR_OK : ERR_UNSUPPORTED;
                    bank0_active_cycles_q         <=
                        command_is_valid ? 64'b0 : 64'd1;
                    bank0_capture_count_q         <= 13'b0;
                    bank0_scalar_launch_count_q   <= 13'b0;
                    bank0_scalar_terminal_count_q <= 13'b0;
                    bank0_success_result_count_q  <= 13'b0;
                    bank0_child_call_mask_q       <= 5'b0;
                    bank0_exp_req_count_q         <= 13'b0;
                    bank0_add_req_count_q         <= 13'b0;
                    bank0_div_req_count_q         <= 13'b0;
                    bank0_log_req_count_q         <= 13'b0;
                    bank0_mul_req_count_q         <= 13'b0;
                    bank0_bypass_count_q          <= 13'b0;
                    bank0_tensor_flags_or_q       <= 5'b0;
                    bank0_fail_elem_valid_q       <= 1'b0;
                    bank0_fail_elem_index_q       <= 13'b0;
                    bank0_out_index_q             <= 13'b0;
                end else begin
                    bank1_state_q                 <=
                        command_is_valid ? BANK_FILL : BANK_READY_ERR;
                    bank1_tag_q                   <= cmd_tag_i;
                    bank1_opcode_q                <= cmd_opcode_i;
                    bank1_length_q                <= cmd_length_i;
                    bank1_error_code_q            <=
                        command_is_valid ? ERR_OK : ERR_UNSUPPORTED;
                    bank1_active_cycles_q         <=
                        command_is_valid ? 64'b0 : 64'd1;
                    bank1_capture_count_q         <= 13'b0;
                    bank1_scalar_launch_count_q   <= 13'b0;
                    bank1_scalar_terminal_count_q <= 13'b0;
                    bank1_success_result_count_q  <= 13'b0;
                    bank1_child_call_mask_q       <= 5'b0;
                    bank1_exp_req_count_q         <= 13'b0;
                    bank1_add_req_count_q         <= 13'b0;
                    bank1_div_req_count_q         <= 13'b0;
                    bank1_log_req_count_q         <= 13'b0;
                    bank1_mul_req_count_q         <= 13'b0;
                    bank1_bypass_count_q          <= 13'b0;
                    bank1_tensor_flags_or_q       <= 5'b0;
                    bank1_fail_elem_valid_q       <= 1'b0;
                    bank1_fail_elem_index_q       <= 13'b0;
                    bank1_out_index_q             <= 13'b0;
                end

                if (command_is_valid) begin
                    ctrl_state_q                 <= CTRL_CAPTURE;
                    source_owner_valid_q         <= 1'b1;
                    active_bank_q                <= alloc_bank;
                    active_opcode_q              <= cmd_opcode_i;
                    active_length_q              <= cmd_length_i;
                    start_ts_q                   <= wall_ts_q;
                    capture_count_q              <= 13'b0;
                    exec_index_q                 <= 13'b0;
                    external_bad_seen_q          <= 1'b0;
                    external_bad_index_q         <= 13'b0;
                    work_scalar_launch_count_q   <= 13'b0;
                    work_scalar_terminal_count_q <= 13'b0;
                    work_success_result_count_q  <= 13'b0;
                    work_child_call_mask_q       <= 5'b0;
                    work_exp_req_count_q         <= 13'b0;
                    work_add_req_count_q         <= 13'b0;
                    work_div_req_count_q         <= 13'b0;
                    work_log_req_count_q         <= 13'b0;
                    work_mul_req_count_q         <= 13'b0;
                    work_bypass_count_q          <= 13'b0;
                    work_tensor_flags_or_q       <= 5'b0;
                end
            end

            // 任意非法parent编码先局部quarantine/reset child；若有owner，
            // 同一edge还会由controller_fault_terminal发布唯一code4。
            if (controller_state_illegal) begin
                ctrl_state_q         <= CTRL_QUARANTINE;
                source_owner_valid_q <= 1'b0;
            end else begin
                case (ctrl_state_q)
                    CTRL_IDLE: begin
                        // command accept在独立原子块中建立owner。
                    end

                    CTRL_CAPTURE: begin
                        if (in_fire) begin
                            src0_mem_q[capture_count_q] <= in_src0_bits_i;
                            src1_mem_q[capture_count_q] <= in_src1_bits_i;
                            capture_count_q             <= capture_count_next;
                            if (capture_bad_this && !external_bad_seen_q) begin
                                external_bad_seen_q  <= 1'b1;
                                external_bad_index_q <= capture_count_q;
                            end
                            if (capture_last_fire) begin
                                if (capture_bad_next) begin
                                    ctrl_state_q         <= CTRL_IDLE;
                                    source_owner_valid_q <= 1'b0;
                                end else begin
                                    ctrl_state_q <= CTRL_EXEC_REQ;
                                    exec_index_q <= 13'b0;
                                end
                            end
                        end
                    end

                    CTRL_EXEC_REQ: begin
                        if (scalar_req_fire) begin
                            work_scalar_launch_count_q <=
                                work_scalar_launch_count_q + 13'd1;
                            ctrl_state_q <= CTRL_EXEC_WAIT;
                        end
                    end

                    CTRL_EXEC_WAIT: begin
                        if (scalar_rsp_fire) begin
                            work_scalar_terminal_count_q <=
                                work_scalar_terminal_count_q + 13'd1;
                            work_child_call_mask_q <=
                                work_child_call_mask_q | element_child_call_mask;
                            if (element_child_call_mask[0]) begin
                                work_exp_req_count_q <= work_exp_req_count_q + 13'd1;
                            end
                            if (element_child_call_mask[1]) begin
                                work_add_req_count_q <= work_add_req_count_q + 13'd1;
                            end
                            if (element_child_call_mask[2]) begin
                                work_div_req_count_q <= work_div_req_count_q + 13'd1;
                            end
                            if (element_child_call_mask[3]) begin
                                work_log_req_count_q <= work_log_req_count_q + 13'd1;
                            end
                            if (element_child_call_mask[4]) begin
                                work_mul_req_count_q <= work_mul_req_count_q + 13'd1;
                            end

                            if (element_error) begin
                                ctrl_state_q         <= CTRL_IDLE;
                                source_owner_valid_q <= 1'b0;
                            end else begin
                                if (!active_bank_q) begin
                                    bank0_result_mem_q[exec_index_q] <= element_result_bits;
                                    bank0_flags_mem_q[exec_index_q]  <= element_flags;
                                end else begin
                                    bank1_result_mem_q[exec_index_q] <= element_result_bits;
                                    bank1_flags_mem_q[exec_index_q]  <= element_flags;
                                end
                                work_success_result_count_q <=
                                    work_success_result_count_q + 13'd1;
                                work_tensor_flags_or_q <=
                                    work_tensor_flags_or_q | element_flags;
                                if ((active_opcode_q == OP_SOFTPLUS) &&
                                    (element_child_call_mask == 5'b0)) begin
                                    work_bypass_count_q <= work_bypass_count_q + 13'd1;
                                end
                                if ((exec_index_q + 13'd1) == active_length_q) begin
                                    ctrl_state_q         <= CTRL_IDLE;
                                    source_owner_valid_q <= 1'b0;
                                end else begin
                                    exec_index_q <= exec_index_q + 13'd1;
                                    ctrl_state_q <= CTRL_EXEC_REQ;
                                end
                            end
                        end
                    end

                    CTRL_QUARANTINE: begin
                        // parent_element_rst在本active edge仍为1；下拍进入IDLE
                        // 后才恢复cmd_ready，旧scalar response不能跨代驻留。
                        ctrl_state_q         <= CTRL_IDLE;
                        source_owner_valid_q <= 1'b0;
                    end

                    default: begin
                        // 四态仿真中default仅作二次fail-closed保护。
                        ctrl_state_q         <= CTRL_QUARANTINE;
                        source_owner_valid_q <= 1'b0;
                    end
                endcase
            end

            // 唯一tensor terminal edge把所有“当前response + old work”原子快照进active bank。
            if (tensor_terminal) begin
                if (!active_bank_q) begin
                    bank0_state_q                 <=
                        tensor_terminal_ok ? BANK_READY_OK : BANK_READY_ERR;
                    bank0_error_code_q            <= tensor_terminal_error_code;
                    bank0_active_cycles_q         <= tensor_terminal_active_cycles;
                    bank0_capture_count_q         <= tensor_terminal_capture_count;
                    bank0_scalar_launch_count_q   <= work_scalar_launch_count_q;
                    bank0_scalar_terminal_count_q <=
                        tensor_terminal_scalar_terminal_count;
                    bank0_success_result_count_q  <=
                        tensor_terminal_success_result_count;
                    bank0_child_call_mask_q       <= tensor_terminal_child_call_mask;
                    bank0_exp_req_count_q         <= tensor_terminal_exp_req_count;
                    bank0_add_req_count_q         <= tensor_terminal_add_req_count;
                    bank0_div_req_count_q         <= tensor_terminal_div_req_count;
                    bank0_log_req_count_q         <= tensor_terminal_log_req_count;
                    bank0_mul_req_count_q         <= tensor_terminal_mul_req_count;
                    bank0_bypass_count_q          <= tensor_terminal_bypass_count;
                    bank0_tensor_flags_or_q       <= tensor_terminal_flags_or;
                    bank0_fail_elem_valid_q       <= tensor_terminal_fail_elem_valid;
                    bank0_fail_elem_index_q       <= tensor_terminal_fail_elem_index;
                    bank0_out_index_q             <= 13'b0;
                end else begin
                    bank1_state_q                 <=
                        tensor_terminal_ok ? BANK_READY_OK : BANK_READY_ERR;
                    bank1_error_code_q            <= tensor_terminal_error_code;
                    bank1_active_cycles_q         <= tensor_terminal_active_cycles;
                    bank1_capture_count_q         <= tensor_terminal_capture_count;
                    bank1_scalar_launch_count_q   <= work_scalar_launch_count_q;
                    bank1_scalar_terminal_count_q <=
                        tensor_terminal_scalar_terminal_count;
                    bank1_success_result_count_q  <=
                        tensor_terminal_success_result_count;
                    bank1_child_call_mask_q       <= tensor_terminal_child_call_mask;
                    bank1_exp_req_count_q         <= tensor_terminal_exp_req_count;
                    bank1_add_req_count_q         <= tensor_terminal_add_req_count;
                    bank1_div_req_count_q         <= tensor_terminal_div_req_count;
                    bank1_log_req_count_q         <= tensor_terminal_log_req_count;
                    bank1_mul_req_count_q         <= tensor_terminal_mul_req_count;
                    bank1_bypass_count_q          <= tensor_terminal_bypass_count;
                    bank1_tensor_flags_or_q       <= tensor_terminal_flags_or;
                    bank1_fail_elem_valid_q       <= tensor_terminal_fail_elem_valid;
                    bank1_fail_elem_index_q       <= tensor_terminal_fail_elem_index;
                    bank1_out_index_q             <= 13'b0;
                end
            end
        end
    end

endmodule
