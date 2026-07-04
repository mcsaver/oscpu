`include "define.v"

// 真实指令到 OoO ALU-only 后端的接入适配层：
// 复用现有 DecodeStage 生成控制包，只允许基础 ALU 子集进入乱序后端。
module OooAluDecodeBackend #(
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W,
  parameter ROB_COUNT_W = `OOO_ROB_COUNT_W,
  parameter FREE_COUNT_W = `OOO_FREE_COUNT_W,
  parameter ISSUE_COUNT_W = `OOO_ISSUE_COUNT_W
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,
  input checkpoint_quiesce_i,
  input mem_issue_block_i,
  input pending_branch_fast_valid_i,
  input [`XLEN-1:0] pending_branch_fast_pc_i,
  input [`XLEN * `REG_NUM - 1:0] recover_gprs_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`XLEN-1:0] dispatch0_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx_i,
  input dispatch0_pred_taken_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`XLEN-1:0] dispatch0_csr_rdata_i,
  output dispatch0_unsupported_o,
  output dispatch0_unsupported_raw_o,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`XLEN-1:0] dispatch1_pred_npc_i,
  input [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx_i,
  input dispatch1_pred_taken_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`XLEN-1:0] dispatch1_csr_rdata_i,
  output dispatch1_unsupported_o,
  output dispatch1_unsupported_raw_o,

  output mem_req_valid_o,
  input mem_req_ready_i,
  output mem_req_write_o,
  output mem_req_probe_o,
  output mem_req_pretrans_o,
  output mem_req_nokill_o,
  output [`XLEN-1:0] mem_req_addr_o,
  output [`XLEN-1:0] mem_req_wdata_o,
  output [`STRB_W-1:0] mem_req_wstrb_o,
  input mem_rsp_valid_i,
  output mem_rsp_ready_o,
  input [`XLEN-1:0] mem_rsp_rdata_i,
  input mem_rsp_error_i,
  input mem_rsp_page_fault_i,
  input mem_translate_active_i,
  input [2:0] frm_i,
  output mem_retire_quiet_o,
  output [4:0] commit0_fflags_o,
  output commit0_is_fp_rd_o,
  output commit1_is_fp_rd_o,
  output [4:0] commit1_fflags_o,

  input commit_ready_i,
  input commit1_block_i,
  output commit0_valid_o,
  output [`XLEN-1:0] commit0_pc_o,
  output [`XLEN-1:0] commit0_next_pc_o,
  output [`INST_W-1:0] commit0_inst_o,
  output commit0_rd_en_o,
  output [`REG_ADDR_W-1:0] commit0_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit0_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit0_new_pdest_o,
  output [`XLEN-1:0] commit0_data_o,
  output commit0_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit0_cause_o,
  output [`XLEN-1:0] commit0_tval_o,

  output commit1_valid_o,
  output [`XLEN-1:0] commit1_pc_o,
  output [`XLEN-1:0] commit1_next_pc_o,
  output [`INST_W-1:0] commit1_inst_o,
  output commit1_rd_en_o,
  output [`REG_ADDR_W-1:0] commit1_arch_rd_o,
  output [PHY_REG_ADDR_W-1:0] commit1_old_pdest_o,
  output [PHY_REG_ADDR_W-1:0] commit1_new_pdest_o,
  output [`XLEN-1:0] commit1_data_o,
  output commit1_exception_o,
  output [`TRAP_CAUSE_W-1:0] commit1_cause_o,
  output [`XLEN-1:0] commit1_tval_o,

  output [FREE_COUNT_W-1:0] free_count_o,
  output [ROB_COUNT_W-1:0] rob_count_o,
  output [ISSUE_COUNT_W-1:0] issue_count_o,
  output mem_idle_o,
  output execute0_valid_o,
  output execute1_valid_o,

  output branch_resolve_valid_o,
  output [`XLEN-1:0] branch_resolve_pc_o,
  output [`XLEN-1:0] branch_resolve_next_pc_o,
  output branch_resolve_misaligned_o,
  output [ROB_INDEX_W-1:0] branch_resolve_rob_idx_o,
  output branch_resolve_mispredict_o,
  output branch_resolve_is_branch_o,
  output branch_resolve_taken_o,
  output branch_resolve_pred_taken_o,
  output [`BPU_BHT_INDEX_W-1:0] branch_resolve_bht_idx_o,
  output dispatch_branch_resolve_valid_o,
  output [`XLEN-1:0] dispatch_branch_resolve_pc_o,
  output [`XLEN-1:0] dispatch_branch_resolve_next_pc_o,
  output dispatch_branch_resolve_misaligned_o
);

  wire [`CTRL_BUS_W-1:0] decode0_ctrl_w;
  wire [`REG_ADDR_W-1:0] decode0_rs1_w;
  wire [`REG_ADDR_W-1:0] decode0_rs2_w;
  wire [`REG_ADDR_W-1:0] decode0_rd_w;
  wire [`XLEN-1:0] decode0_imm_w;

  wire [`CTRL_BUS_W-1:0] decode1_ctrl_w;
  wire [`REG_ADDR_W-1:0] decode1_rs1_w;
  wire [`REG_ADDR_W-1:0] decode1_rs2_w;
  wire [`REG_ADDR_W-1:0] decode1_rd_w;
  wire [`XLEN-1:0] decode1_imm_w;

  DecodeStage u_decode0 (
    .inst_i(dispatch0_inst_i),
    .ctrl_o(decode0_ctrl_w),
    .rs1_idx_o(decode0_rs1_w),
    .rs2_idx_o(decode0_rs2_w),
    .rd_idx_o(decode0_rd_w),
    .imm_o(decode0_imm_w)
  );

  DecodeStage u_decode1 (
    .inst_i(dispatch1_inst_i),
    .ctrl_o(decode1_ctrl_w),
    .rs1_idx_o(decode1_rs1_w),
    .rs2_idx_o(decode1_rs2_w),
    .rd_idx_o(decode1_rd_w),
    .imm_o(decode1_imm_w)
  );

  // 只把支持性判定位送入 helper，避免把整条控制总线当成伪消费者。
  function ctrl_supported;
    input ctrl_valid;
    input ctrl_illegal;
    input ctrl_need_exec;
    input ctrl_system;
    input ctrl_csr;
    input ctrl_mret;
    input ctrl_sret;
    input ctrl_wfi;
    input ctrl_sfence_vma;
    begin
      ctrl_supported = ctrl_valid &&
                       !ctrl_illegal &&
                       ctrl_need_exec &&
                       (!ctrl_system || ctrl_csr) &&
                       !ctrl_mret &&
                       !ctrl_sret &&
                       !ctrl_wfi &&
                       !ctrl_sfence_vma;
    end
  endfunction

  wire dispatch0_supported_w =
      ctrl_supported(decode0_ctrl_w[`CTRL_VALID_BIT],
                     decode0_ctrl_w[`CTRL_ILLEGAL_BIT],
                     decode0_ctrl_w[`CTRL_NEED_EXEC_BIT],
                     decode0_ctrl_w[`CTRL_SYSTEM_BIT],
                     decode0_ctrl_w[`CTRL_CSR_BIT],
                     decode0_ctrl_w[`CTRL_MRET_BIT],
                     decode0_ctrl_w[`CTRL_SRET_BIT],
                     decode0_ctrl_w[`CTRL_WFI_BIT],
                     decode0_ctrl_w[`CTRL_SFENCE_VMA_BIT]);
  wire dispatch1_supported_w =
      ctrl_supported(decode1_ctrl_w[`CTRL_VALID_BIT],
                     decode1_ctrl_w[`CTRL_ILLEGAL_BIT],
                     decode1_ctrl_w[`CTRL_NEED_EXEC_BIT],
                     decode1_ctrl_w[`CTRL_SYSTEM_BIT],
                     decode1_ctrl_w[`CTRL_CSR_BIT],
                     decode1_ctrl_w[`CTRL_MRET_BIT],
                     decode1_ctrl_w[`CTRL_SRET_BIT],
                     decode1_ctrl_w[`CTRL_WFI_BIT],
                     decode1_ctrl_w[`CTRL_SFENCE_VMA_BIT]);
  // CSR 旧值作为该 uop 的写回数据，复用 imm payload 穿过 rename/issue/ROB。
  wire [`XLEN-1:0] backend_dispatch0_imm_w =
      decode0_ctrl_w[`CTRL_CSR_BIT] ? dispatch0_csr_rdata_i : decode0_imm_w;
  wire [`XLEN-1:0] backend_dispatch1_imm_w =
      decode1_ctrl_w[`CTRL_CSR_BIT] ? dispatch1_csr_rdata_i : decode1_imm_w;

  // ===== 【B-FP 簇】FP 指令旁路 decode(spec ooo-fp-cluster §7) =====
  // 后端 DecodeUnit 不认识 FP opcode(会判 unsupported 卡死 dispatch)。FP 指令在
  // 此旁路: supported 豁免 + 合成最小 ctrl——FP mem 置 LOAD/STORE/MEM_SIZE/RS1_EN
  // 走整数 IQ mem 通道; FP 算术置 VALID/NEED_EXEC(操作数/目的全在 FP 簇, 整数
  // rename 天然 bypass)。GPR 目的(FCMP/FCLASS/FMV.X/FCVT.to-int)置 RD_EN 走正常
  // 整数 rename。lane 约束: FP 算术只走 lane0; lane1 仅允许 FP load(且 lane0 非
  // FP load)——其余 FP 在 lane1 时 valid gate(前端 optional 机制下拍推进)。
  localparam [6:0] FPD_F7_FCMP_S = 7'b1010000, FPD_F7_FCMP_D = 7'b1010001;
  localparam [6:0] FPD_F7_FMVX_S = 7'b1110000, FPD_F7_FMVX_D = 7'b1110001;
  localparam [6:0] FPD_F7_FCVT_S_INT = 7'b1100000, FPD_F7_FCVT_D_INT = 7'b1100001;
  localparam [6:0] FPD_F7_FCVT_INT_S = 7'b1101000, FPD_F7_FCVT_INT_D = 7'b1101001;
  localparam [6:0] FPD_F7_FMV_W_X = 7'b1111000, FPD_F7_FMV_D_X = 7'b1111001;
  localparam [6:0] FPD_F7_FSQRT_S = 7'b0101100, FPD_F7_FSQRT_D = 7'b0101101;
  localparam [6:0] FPD_F7_FCVT_S_D = 7'b0100000, FPD_F7_FCVT_D_S = 7'b0100001;

  function fp_classify_gpr_write;
    input [31:0] inst;
    begin
      fp_classify_gpr_write =
          (inst[31:25] == FPD_F7_FCMP_S) || (inst[31:25] == FPD_F7_FCMP_D) ||
          (inst[31:25] == FPD_F7_FMVX_S) || (inst[31:25] == FPD_F7_FMVX_D) ||
          (inst[31:25] == FPD_F7_FCVT_S_INT) ||
          (inst[31:25] == FPD_F7_FCVT_D_INT);
    end
  endfunction
  function fp_classify_gpr_src;
    input [31:0] inst;
    begin
      fp_classify_gpr_src =
          (inst[31:25] == FPD_F7_FMV_W_X) || (inst[31:25] == FPD_F7_FMV_D_X) ||
          (inst[31:25] == FPD_F7_FCVT_INT_S) ||
          (inst[31:25] == FPD_F7_FCVT_INT_D);
    end
  endfunction
  function fp_classify_single_src;
    input [31:0] inst;
    begin
      // 单 FP 源: FSQRT / FCVT(fp↔fp, fp→int) / FMV.X / FCLASS
      fp_classify_single_src =
          (inst[31:25] == FPD_F7_FSQRT_S) || (inst[31:25] == FPD_F7_FSQRT_D) ||
          (inst[31:25] == FPD_F7_FCVT_S_D) || (inst[31:25] == FPD_F7_FCVT_D_S) ||
          (inst[31:25] == FPD_F7_FCVT_S_INT) ||
          (inst[31:25] == FPD_F7_FCVT_D_INT) ||
          (inst[31:25] == FPD_F7_FMVX_S) || (inst[31:25] == FPD_F7_FMVX_D);
    end
  endfunction

  wire d0_op_fp_w = dispatch0_inst_i[6:0] == `OPCODE_OP_FP;
  wire d0_fma_w = (dispatch0_inst_i[6:0] == `OPCODE_MADD) ||
                  (dispatch0_inst_i[6:0] == `OPCODE_MSUB) ||
                  (dispatch0_inst_i[6:0] == `OPCODE_NMSUB) ||
                  (dispatch0_inst_i[6:0] == `OPCODE_NMADD);
  wire d0_fp_load_w = (dispatch0_inst_i[6:0] == 7'b0000111) &&
                      ((dispatch0_inst_i[14:12] == 3'b010) ||
                       (dispatch0_inst_i[14:12] == 3'b011));
  wire d0_fp_store_w = (dispatch0_inst_i[6:0] == 7'b0100111) &&
                       ((dispatch0_inst_i[14:12] == 3'b010) ||
                        (dispatch0_inst_i[14:12] == 3'b011));
  wire d0_is_fp_w = d0_op_fp_w || d0_fma_w || d0_fp_load_w || d0_fp_store_w;
  wire d0_fp_mem_w = d0_fp_load_w || d0_fp_store_w;
  wire d0_fp_gpr_write_w = d0_op_fp_w &&
                           fp_classify_gpr_write(dispatch0_inst_i);
  wire d0_fp_gpr_src_w = d0_op_fp_w && fp_classify_gpr_src(dispatch0_inst_i);
  wire d0_fp_double_w =
      d0_fp_mem_w ? (dispatch0_inst_i[14:12] == 3'b011) :
      d0_fma_w ? (dispatch0_inst_i[26:25] == 2'b01) :
                 dispatch0_inst_i[25];
  wire d0_fp_fs1_en_w = (d0_op_fp_w && !d0_fp_gpr_src_w) || d0_fma_w;
  wire d0_fp_fs2_en_w = d0_fma_w ||
      (d0_op_fp_w && !d0_fp_gpr_src_w &&
       !fp_classify_single_src(dispatch0_inst_i) &&
       !((dispatch0_inst_i[31:25] == FPD_F7_FMVX_S ||
          dispatch0_inst_i[31:25] == FPD_F7_FMVX_D) &&
         dispatch0_inst_i[14:12] == 3'b001));
  wire d0_fp_fs3_en_w = d0_fma_w;

  wire d1_op_fp_w = dispatch1_inst_i[6:0] == `OPCODE_OP_FP;
  wire d1_fma_w = (dispatch1_inst_i[6:0] == `OPCODE_MADD) ||
                  (dispatch1_inst_i[6:0] == `OPCODE_MSUB) ||
                  (dispatch1_inst_i[6:0] == `OPCODE_NMSUB) ||
                  (dispatch1_inst_i[6:0] == `OPCODE_NMADD);
  wire d1_fp_load_w = (dispatch1_inst_i[6:0] == 7'b0000111) &&
                      ((dispatch1_inst_i[14:12] == 3'b010) ||
                       (dispatch1_inst_i[14:12] == 3'b011));
  wire d1_fp_store_w = (dispatch1_inst_i[6:0] == 7'b0100111) &&
                       ((dispatch1_inst_i[14:12] == 3'b010) ||
                        (dispatch1_inst_i[14:12] == 3'b011));
  wire d1_is_fp_w = d1_op_fp_w || d1_fma_w || d1_fp_load_w || d1_fp_store_w;
  wire d1_fp_mem_w = d1_fp_load_w || d1_fp_store_w;
  wire d1_fp_gpr_write_w = d1_op_fp_w &&
                           fp_classify_gpr_write(dispatch1_inst_i);
  wire d1_fp_gpr_src_w = d1_op_fp_w && fp_classify_gpr_src(dispatch1_inst_i);
  wire d1_fp_double_w =
      d1_fp_mem_w ? (dispatch1_inst_i[14:12] == 3'b011) :
      d1_fma_w ? (dispatch1_inst_i[26:25] == 2'b01) :
                 dispatch1_inst_i[25];
  wire d1_fp_fs1_en_w = (d1_op_fp_w && !d1_fp_gpr_src_w) || d1_fma_w;
  wire d1_fp_fs2_en_w = d1_fma_w ||
      (d1_op_fp_w && !d1_fp_gpr_src_w &&
       !fp_classify_single_src(dispatch1_inst_i) &&
       !((dispatch1_inst_i[31:25] == FPD_F7_FMVX_S ||
          dispatch1_inst_i[31:25] == FPD_F7_FMVX_D) &&
         dispatch1_inst_i[14:12] == 3'b001));
  wire d1_fp_fs3_en_w = d1_fma_w;
  // lane1 全 FP 放开(FP 簇 rename/IQ 双 lane 化后无口数约束)
  wire d1_fp_allow_w = d1_is_fp_w;

  // 合成 ctrl(FP mem: LOAD/STORE+SIZE+RS1_EN; FP 算术: GPR 目的置 RD_EN)
  wire [1:0] d0_fp_mem_size_w = d0_fp_double_w ? `MEM_SIZE_DWORD
                                               : `MEM_SIZE_WORD;
  wire [1:0] d1_fp_mem_size_w = d1_fp_double_w ? `MEM_SIZE_DWORD
                                               : `MEM_SIZE_WORD;
  wire [`CTRL_BUS_W-1:0] d0_fp_ctrl_w =
      ({`CTRL_BUS_W{1'b0}}) |
      (`CTRL_BUS_W'b1 << `CTRL_VALID_BIT) |
      (`CTRL_BUS_W'b1 << `CTRL_NEED_EXEC_BIT) |
      (d0_fp_load_w ? (`CTRL_BUS_W'b1 << `CTRL_LOAD_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_store_w ? (`CTRL_BUS_W'b1 << `CTRL_STORE_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_mem_w ? (`CTRL_BUS_W'b1 << `CTRL_RS1_EN_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_mem_w ? ({{(`CTRL_BUS_W-2){1'b0}}, `OP2_SEL_IMM} << `CTRL_OP2_SEL_LSB)
                   : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_mem_w ? ({{(`CTRL_BUS_W-2){1'b0}}, d0_fp_mem_size_w} << `CTRL_MEM_SIZE_LSB)
                   : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_load_w ? ({{(`CTRL_BUS_W-3){1'b0}}, `IMM_TYPE_I} << `CTRL_IMM_TYPE_LSB)
                    : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_store_w ? ({{(`CTRL_BUS_W-3){1'b0}}, `IMM_TYPE_S} << `CTRL_IMM_TYPE_LSB)
                     : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_gpr_write_w ? (`CTRL_BUS_W'b1 << `CTRL_RD_EN_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d0_fp_gpr_src_w ? (`CTRL_BUS_W'b1 << `CTRL_RS1_EN_BIT) : {`CTRL_BUS_W{1'b0}});
  wire [`CTRL_BUS_W-1:0] d1_fp_ctrl_w =
      ({`CTRL_BUS_W{1'b0}}) |
      (`CTRL_BUS_W'b1 << `CTRL_VALID_BIT) |
      (`CTRL_BUS_W'b1 << `CTRL_NEED_EXEC_BIT) |
      (d1_fp_load_w ? (`CTRL_BUS_W'b1 << `CTRL_LOAD_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_store_w ? (`CTRL_BUS_W'b1 << `CTRL_STORE_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_mem_w ? (`CTRL_BUS_W'b1 << `CTRL_RS1_EN_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_mem_w ? ({{(`CTRL_BUS_W-2){1'b0}}, d1_fp_mem_size_w} << `CTRL_MEM_SIZE_LSB)
                   : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_load_w ? ({{(`CTRL_BUS_W-3){1'b0}}, `IMM_TYPE_I} << `CTRL_IMM_TYPE_LSB)
                    : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_store_w ? ({{(`CTRL_BUS_W-3){1'b0}}, `IMM_TYPE_S} << `CTRL_IMM_TYPE_LSB)
                     : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_mem_w ? ({{(`CTRL_BUS_W-2){1'b0}}, `OP2_SEL_IMM} << `CTRL_OP2_SEL_LSB)
                   : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_gpr_write_w ? (`CTRL_BUS_W'b1 << `CTRL_RD_EN_BIT) : {`CTRL_BUS_W{1'b0}}) |
      (d1_fp_gpr_src_w ? (`CTRL_BUS_W'b1 << `CTRL_RS1_EN_BIT) : {`CTRL_BUS_W{1'b0}});

  wire [`CTRL_BUS_W-1:0] backend_dispatch0_ctrl_w =
      d0_is_fp_w ? d0_fp_ctrl_w : decode0_ctrl_w;
  wire [`CTRL_BUS_W-1:0] backend_dispatch1_ctrl_w =
      d1_is_fp_w ? d1_fp_ctrl_w : decode1_ctrl_w;
  // FP mem 的 imm 手工拼(DecodeStage 内部 ImmGen 挂在其自身 ctrl 上, 对 FP
  // opcode 拼不出正确类型): FLW/FLD=I 型, FSW/FSD=S 型。
  wire [`XLEN-1:0] d0_fp_imm_w = d0_fp_store_w ?
      {{52{dispatch0_inst_i[31]}}, dispatch0_inst_i[31:25],
       dispatch0_inst_i[11:7]} :
      {{52{dispatch0_inst_i[31]}}, dispatch0_inst_i[31:20]};
  wire [`XLEN-1:0] d1_fp_imm_w = d1_fp_store_w ?
      {{52{dispatch1_inst_i[31]}}, dispatch1_inst_i[31:25],
       dispatch1_inst_i[11:7]} :
      {{52{dispatch1_inst_i[31]}}, dispatch1_inst_i[31:20]};
  wire [`XLEN-1:0] fp_dispatch0_imm_w =
      d0_is_fp_w ? d0_fp_imm_w : backend_dispatch0_imm_w;
  wire [`XLEN-1:0] fp_dispatch1_imm_w =
      d1_is_fp_w ? d1_fp_imm_w : backend_dispatch1_imm_w;

  wire backend_dispatch0_valid_w =
      dispatch0_valid_i && (dispatch0_supported_w || d0_is_fp_w);
  wire backend_dispatch1_valid_w =
      dispatch1_valid_i &&
      (d1_is_fp_w ? d1_fp_allow_w : dispatch1_supported_w);
  wire backend_dispatch0_ready_w;
  wire backend_dispatch1_ready_w;

  assign dispatch0_ready_o = (dispatch0_supported_w || d0_is_fp_w) &&
                             backend_dispatch0_ready_w;
  assign dispatch1_ready_o = (d1_is_fp_w ? d1_fp_allow_w
                                         : dispatch1_supported_w) &&
                             backend_dispatch1_ready_w;
  assign dispatch0_unsupported_o =
      dispatch0_valid_i && !dispatch0_supported_w && !d0_is_fp_w;
  assign dispatch1_unsupported_o =
      dispatch1_valid_i && !dispatch1_supported_w && !d1_is_fp_w;
  // 【F2】裸支持性(纯 inst 组合, 不含 valid): 前端 dual_go 谓词用——含 valid 版
  // 经 core_dispatch1_valid←dual_go 成 UNOPTFLAT 环。
  assign dispatch0_unsupported_raw_o = !dispatch0_supported_w && !d0_is_fp_w;
  assign dispatch1_unsupported_raw_o = !dispatch1_supported_w && !d1_is_fp_w;

  OooIntBackend #(
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .ROB_COUNT_W(ROB_COUNT_W),
    .FREE_COUNT_W(FREE_COUNT_W),
    .ISSUE_COUNT_W(ISSUE_COUNT_W)
  ) u_int_backend (
    .clk(clk),
    .rst(rst),
    .flush_i(flush_i),
    .checkpoint_capture_i(checkpoint_capture_i),
	    .checkpoint_restore_i(checkpoint_restore_i),
	    .checkpoint_quiesce_i(checkpoint_quiesce_i),
	    .mem_issue_block_i(mem_issue_block_i),
	    .pending_branch_fast_valid_i(pending_branch_fast_valid_i),
	    .pending_branch_fast_pc_i(pending_branch_fast_pc_i),
	    .recover_gprs_i(recover_gprs_i),
	    .dispatch0_valid_i(backend_dispatch0_valid_w),
    .dispatch0_ready_o(backend_dispatch0_ready_w),
    .dispatch0_pc_i(dispatch0_pc_i),
    .dispatch0_next_pc_i(dispatch0_next_pc_i),
    .dispatch0_pred_npc_i(dispatch0_pred_npc_i),
    .dispatch0_bht_idx_i(dispatch0_bht_idx_i),
    .dispatch0_pred_taken_i(dispatch0_pred_taken_i),
    .dispatch0_inst_i(dispatch0_inst_i),
    .dispatch0_ctrl_i(backend_dispatch0_ctrl_w),
    .dispatch0_rs1_arch_i(decode0_rs1_w),
    .dispatch0_rs2_arch_i(decode0_rs2_w),
    .dispatch0_rd_arch_i(decode0_rd_w),
    .dispatch0_imm_i(fp_dispatch0_imm_w),
    .dispatch1_valid_i(backend_dispatch1_valid_w),
    .dispatch1_optional_i(dispatch1_optional_i),
    .dispatch1_ready_o(backend_dispatch1_ready_w),
    .dispatch1_pc_i(dispatch1_pc_i),
    .dispatch1_next_pc_i(dispatch1_next_pc_i),
    .dispatch1_pred_npc_i(dispatch1_pred_npc_i),
    .dispatch1_bht_idx_i(dispatch1_bht_idx_i),
    .dispatch1_pred_taken_i(dispatch1_pred_taken_i),
    .dispatch1_inst_i(dispatch1_inst_i),
    .dispatch1_ctrl_i(backend_dispatch1_ctrl_w),
    .dispatch0_is_fp_i(d0_is_fp_w),
    .dispatch0_fp_load_i(d0_fp_load_w),
    .dispatch0_fp_store_i(d0_fp_store_w),
    .dispatch0_fp_double_i(d0_fp_double_w),
    .dispatch0_fp_gpr_write_i(d0_fp_gpr_write_w),
    .dispatch0_fp_gpr_src_i(d0_fp_gpr_src_w),
    .dispatch0_fp_fs1_en_i(d0_fp_fs1_en_w),
    .dispatch0_fp_fs2_en_i(d0_fp_fs2_en_w),
    .dispatch0_fp_fs3_en_i(d0_fp_fs3_en_w),
    .dispatch1_is_fp_i(d1_is_fp_w && d1_fp_allow_w),
    .dispatch1_fp_load_i(d1_fp_load_w),
    .dispatch1_fp_store_i(d1_fp_store_w),
    .dispatch1_fp_double_i(d1_fp_double_w),
    .dispatch1_fp_gpr_write_i(d1_fp_gpr_write_w),
    .dispatch1_fp_gpr_src_i(d1_fp_gpr_src_w),
    .dispatch1_fp_fs1_en_i(d1_fp_fs1_en_w),
    .dispatch1_fp_fs2_en_i(d1_fp_fs2_en_w),
    .dispatch1_fp_fs3_en_i(d1_fp_fs3_en_w),
    .dispatch1_rs1_arch_i(decode1_rs1_w),
    .dispatch1_rs2_arch_i(decode1_rs2_w),
    .dispatch1_rd_arch_i(decode1_rd_w),
    .dispatch1_imm_i(fp_dispatch1_imm_w),
    .mem_req_valid_o(mem_req_valid_o),
    .mem_req_ready_i(mem_req_ready_i),
    .mem_req_write_o(mem_req_write_o),
    .mem_req_probe_o(mem_req_probe_o),
    .mem_req_pretrans_o(mem_req_pretrans_o),
    .mem_req_nokill_o(mem_req_nokill_o),
    .mem_req_addr_o(mem_req_addr_o),
    .mem_req_wdata_o(mem_req_wdata_o),
    .mem_req_wstrb_o(mem_req_wstrb_o),
    .mem_rsp_valid_i(mem_rsp_valid_i),
    .mem_rsp_ready_o(mem_rsp_ready_o),
    .mem_rsp_rdata_i(mem_rsp_rdata_i),
    .mem_rsp_error_i(mem_rsp_error_i),
    .mem_rsp_page_fault_i(mem_rsp_page_fault_i),
    .mem_translate_active_i(mem_translate_active_i),
    .frm_i(frm_i),
    .mem_retire_quiet_o(mem_retire_quiet_o),
    .commit0_fflags_o(commit0_fflags_o),
    .commit0_is_fp_rd_o(commit0_is_fp_rd_o),
    .commit1_is_fp_rd_o(commit1_is_fp_rd_o),
    .commit1_fflags_o(commit1_fflags_o),
    .commit_ready_i(commit_ready_i),
    .commit1_block_i(commit1_block_i),
    .commit0_valid_o(commit0_valid_o),
    .commit0_pc_o(commit0_pc_o),
    .commit0_next_pc_o(commit0_next_pc_o),
    .commit0_inst_o(commit0_inst_o),
    .commit0_rd_en_o(commit0_rd_en_o),
    .commit0_arch_rd_o(commit0_arch_rd_o),
    .commit0_old_pdest_o(commit0_old_pdest_o),
    .commit0_new_pdest_o(commit0_new_pdest_o),
    .commit0_data_o(commit0_data_o),
    .commit0_exception_o(commit0_exception_o),
    .commit0_cause_o(commit0_cause_o),
    .commit0_tval_o(commit0_tval_o),
    .commit1_valid_o(commit1_valid_o),
    .commit1_pc_o(commit1_pc_o),
    .commit1_next_pc_o(commit1_next_pc_o),
    .commit1_inst_o(commit1_inst_o),
    .commit1_rd_en_o(commit1_rd_en_o),
    .commit1_arch_rd_o(commit1_arch_rd_o),
    .commit1_old_pdest_o(commit1_old_pdest_o),
    .commit1_new_pdest_o(commit1_new_pdest_o),
    .commit1_data_o(commit1_data_o),
    .commit1_exception_o(commit1_exception_o),
    .commit1_cause_o(commit1_cause_o),
    .commit1_tval_o(commit1_tval_o),
    .free_count_o(free_count_o),
    .rob_count_o(rob_count_o),
    .issue_count_o(issue_count_o),
    .mem_idle_o(mem_idle_o),
    .execute0_valid_o(execute0_valid_o),
	    .execute1_valid_o(execute1_valid_o),
	    .branch_resolve_valid_o(branch_resolve_valid_o),
	    .branch_resolve_pc_o(branch_resolve_pc_o),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc_o),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned_o),
	    .branch_resolve_rob_idx_o(branch_resolve_rob_idx_o),
	    .branch_resolve_mispredict_o(branch_resolve_mispredict_o),
	    .branch_resolve_is_branch_o(branch_resolve_is_branch_o),
	    .branch_resolve_taken_o(branch_resolve_taken_o),
	    .branch_resolve_pred_taken_o(branch_resolve_pred_taken_o),
	    .branch_resolve_bht_idx_o(branch_resolve_bht_idx_o),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid_o),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc_o),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc_o),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned_o)
  );

endmodule
