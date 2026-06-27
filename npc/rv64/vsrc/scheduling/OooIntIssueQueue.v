`include "define.v"

// 整数 issue queue 先覆盖 ALU-only uop 的乱序发射核心动作：
// 保持队列内程序序，监听两个 writeback wakeup，每拍最多发射两个最老 ready uop。
module OooIntIssueQueue #(
  parameter ENTRY_COUNT = (1 << `OOO_ISSUE_INDEX_W),
  parameter ENTRY_INDEX_W = `OOO_ISSUE_INDEX_W,
  parameter ENTRY_COUNT_W = `OOO_ISSUE_COUNT_W,
  parameter PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W,
  parameter ROB_INDEX_W = `OOO_ROB_INDEX_W
) (
  input clk,
  input rst,
  input flush_i,
  input checkpoint_capture_i,
  input checkpoint_restore_i,
  input issue_mem_block_i,

  input dispatch0_valid_i,
  output dispatch0_ready_o,
  input [`XLEN-1:0] dispatch0_pc_i,
  input [`XLEN-1:0] dispatch0_next_pc_i,
  input [`INST_W-1:0] dispatch0_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch0_ctrl_i,
  input [ROB_INDEX_W-1:0] dispatch0_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_src1_preg_i,
  input dispatch0_src1_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_src2_preg_i,
  input dispatch0_src2_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch0_pdest_i,
  input [`XLEN-1:0] dispatch0_imm_i,

  input dispatch1_valid_i,
  input dispatch1_optional_i,
  output dispatch1_ready_o,
  input [`XLEN-1:0] dispatch1_pc_i,
  input [`XLEN-1:0] dispatch1_next_pc_i,
  input [`INST_W-1:0] dispatch1_inst_i,
  input [`CTRL_BUS_W-1:0] dispatch1_ctrl_i,
  input [ROB_INDEX_W-1:0] dispatch1_rob_idx_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_src1_preg_i,
  input dispatch1_src1_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_src2_preg_i,
  input dispatch1_src2_ready_i,
  input [PHY_REG_ADDR_W-1:0] dispatch1_pdest_i,
  input [`XLEN-1:0] dispatch1_imm_i,

  input wakeup0_valid_i,
  input [PHY_REG_ADDR_W-1:0] wakeup0_pdest_i,
  input wakeup1_valid_i,
  input [PHY_REG_ADDR_W-1:0] wakeup1_pdest_i,
  input pending_load0_valid_i,
  input [PHY_REG_ADDR_W-1:0] pending_load0_pdest_i,
  input pending_load1_valid_i,
  input [PHY_REG_ADDR_W-1:0] pending_load1_pdest_i,

  output issue0_valid_o,
  input issue0_ready_i,
  output [`XLEN-1:0] issue0_pc_o,
  output [`XLEN-1:0] issue0_next_pc_o,
  output [`INST_W-1:0] issue0_inst_o,
  output [`CTRL_BUS_W-1:0] issue0_ctrl_o,
  output [ROB_INDEX_W-1:0] issue0_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue0_pdest_o,
  output [`XLEN-1:0] issue0_imm_o,

  output issue1_valid_o,
  input issue1_ready_i,
  output [`XLEN-1:0] issue1_pc_o,
  output [`XLEN-1:0] issue1_next_pc_o,
  output [`INST_W-1:0] issue1_inst_o,
  output [`CTRL_BUS_W-1:0] issue1_ctrl_o,
  output [ROB_INDEX_W-1:0] issue1_rob_idx_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_src2_preg_o,
  output [PHY_REG_ADDR_W-1:0] issue1_pdest_o,
  output [`XLEN-1:0] issue1_imm_o,

  output [ENTRY_COUNT_W-1:0] count_o,
  output empty_o,
  output full_o,
  output pending_load_branch_dep_o,
  output load_branch_fast_valid_o,
  output [ROB_INDEX_W-1:0] load_branch_fast_rob_idx_o,
  output [`XLEN-1:0] load_branch_fast_pc_o,
  output [`XLEN-1:0] load_branch_fast_next_pc_o,
  output [`XLEN-1:0] load_branch_fast_imm_o,
  output [2:0] load_branch_fast_cmp_op_o,
  output [PHY_REG_ADDR_W-1:0] load_branch_fast_src1_preg_o,
  output [PHY_REG_ADDR_W-1:0] load_branch_fast_src2_preg_o,
  output load_branch_fast_wait_load0_o,
  output load_branch_fast_wait_load1_o
);

  reg valid_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_q [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl_q [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src1_preg_q [0:ENTRY_COUNT-1];
  reg src1_ready_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src2_preg_q [0:ENTRY_COUNT-1];
  reg src2_ready_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] pdest_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] imm_q [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W-1:0] count_q;

  reg checkpoint_valid_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] checkpoint_pc_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] checkpoint_next_pc_q [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] checkpoint_inst_q [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] checkpoint_ctrl_q [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] checkpoint_rob_idx_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] checkpoint_src1_preg_q [0:ENTRY_COUNT-1];
  reg checkpoint_src1_ready_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] checkpoint_src2_preg_q [0:ENTRY_COUNT-1];
  reg checkpoint_src2_ready_q [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] checkpoint_pdest_q [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] checkpoint_imm_q [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W-1:0] checkpoint_count_q;

  reg valid_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] pc_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] next_pc_next_r [0:ENTRY_COUNT-1];
  reg [`INST_W-1:0] inst_next_r [0:ENTRY_COUNT-1];
  reg [`CTRL_BUS_W-1:0] ctrl_next_r [0:ENTRY_COUNT-1];
  reg [ROB_INDEX_W-1:0] rob_idx_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src1_preg_next_r [0:ENTRY_COUNT-1];
  reg src1_ready_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] src2_preg_next_r [0:ENTRY_COUNT-1];
  reg src2_ready_next_r [0:ENTRY_COUNT-1];
  reg [PHY_REG_ADDR_W-1:0] pdest_next_r [0:ENTRY_COUNT-1];
  reg [`XLEN-1:0] imm_next_r [0:ENTRY_COUNT-1];
  reg [ENTRY_COUNT_W-1:0] count_next_r;

  reg issue0_found_r;
  reg issue1_found_r;
  reg issue0_dispatch0_r;
  reg issue0_dispatch1_r;
  reg issue1_dispatch0_r;
  reg issue1_dispatch1_r;
  reg issue0_mem_r;
  reg issue0_load_r;
  reg issue0_forward_r;
  reg [PHY_REG_ADDR_W-1:0] issue0_pdest_r;
  reg dispatch0_entry_ready_for_issue1_r;
  reg dispatch1_entry_ready_for_issue1_r;
  reg issue1_depends_on_issue0_r;
  reg older_store_seen_r;
  reg older_valid_seen_r;
  reg pending_load_branch_dep_r;
  reg load_branch_fast_valid_r;
  reg [ROB_INDEX_W-1:0] load_branch_fast_rob_idx_r;
  reg [`XLEN-1:0] load_branch_fast_pc_r;
  reg [`XLEN-1:0] load_branch_fast_next_pc_r;
  reg [`XLEN-1:0] load_branch_fast_imm_r;
  reg [2:0] load_branch_fast_cmp_op_r;
  reg [PHY_REG_ADDR_W-1:0] load_branch_fast_src1_preg_r;
  reg [PHY_REG_ADDR_W-1:0] load_branch_fast_src2_preg_r;
  reg load_branch_fast_wait_load0_r;
  reg load_branch_fast_wait_load1_r;
  reg src1_load0_match_r;
  reg src1_load1_match_r;
  reg src2_load0_match_r;
  reg src2_load1_match_r;
  reg branch_src1_fast_ready_r;
  reg branch_src2_fast_ready_r;
  reg entry_load_r;
  reg entry_store_r;
  reg entry_mem_order_block_r;
  reg queued_store_valid_r;
  reg [ENTRY_INDEX_W-1:0] issue0_idx_r;
  reg [ENTRY_INDEX_W-1:0] issue1_idx_r;
  reg entry_ready_r [0:ENTRY_COUNT-1];

  wire issue0_fire_w = issue0_valid_o && issue0_ready_i;
  wire issue1_fire_w = issue1_valid_o && issue1_ready_i;
  wire [ENTRY_COUNT_W-1:0] free_slots_w =
      ENTRY_COUNT[ENTRY_COUNT_W-1:0] - count_q;
  wire dispatch0_fire_w = dispatch0_valid_i && dispatch0_ready_o;
  wire dispatch1_fire_w = dispatch1_valid_i && dispatch1_ready_o;

  integer scan_i;
  integer compact_i;
  integer write_i;
  integer reset_i;
  integer store_scan_i;

  function wakeup_match;
    input [PHY_REG_ADDR_W-1:0] preg;
    input wakeup0_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup0_pdest;
    input wakeup1_valid;
    input [PHY_REG_ADDR_W-1:0] wakeup1_pdest;
    begin
      wakeup_match = (preg != {PHY_REG_ADDR_W{1'b0}}) &&
                     ((wakeup0_valid && (wakeup0_pdest == preg)) ||
                      (wakeup1_valid && (wakeup1_pdest == preg)));
    end
  endfunction

  function ctrl_is_mem;
    input ctrl_load;
    input ctrl_store;
    begin
      ctrl_is_mem = ctrl_load || ctrl_store;
    end
  endfunction

  function ctrl_is_control;
    input ctrl_branch;
    input ctrl_jal;
    input ctrl_jalr;
    input ctrl_ecall;
    input ctrl_ebreak;
    input ctrl_system;
    input ctrl_mret;
    input ctrl_wfi;
    begin
      ctrl_is_control = ctrl_branch || ctrl_jal || ctrl_jalr ||
                        ctrl_ecall || ctrl_ebreak || ctrl_system ||
                        ctrl_mret || ctrl_wfi;
    end
  endfunction

  function ctrl_can_forward;
    input ctrl_load;
    input ctrl_store;
    input ctrl_branch;
    input ctrl_jal;
    input ctrl_jalr;
    input ctrl_ecall;
    input ctrl_ebreak;
    input ctrl_system;
    input ctrl_mret;
    input ctrl_wfi;
    input ctrl_muldiv;
    input ctrl_clmul;
    begin
      ctrl_can_forward =
          !ctrl_is_mem(ctrl_load, ctrl_store) &&
          !ctrl_is_control(ctrl_branch, ctrl_jal, ctrl_jalr, ctrl_ecall,
                           ctrl_ebreak, ctrl_system, ctrl_mret, ctrl_wfi) &&
          !ctrl_muldiv && !ctrl_clmul;
    end
  endfunction

  function is_clmul_inst;
    input [`INST_W-1:0] inst;
    begin
      is_clmul_inst =
          (inst[6:0] == `OPCODE_OP) && (inst[31:25] == 7'h05) &&
          ((inst[14:12] == `FUNCT3_SLL) ||
           (inst[14:12] == `FUNCT3_SLT) ||
           (inst[14:12] == `FUNCT3_SLTU));
    end
  endfunction

  function dispatch_entry_ready_with_issue0;
    input dispatch_fire;
    input dispatch_bypass_allowed;
    input src1_ready;
    input [PHY_REG_ADDR_W-1:0] src1_preg;
    input src2_ready;
    input [PHY_REG_ADDR_W-1:0] src2_preg;
    input issue0_forward;
    input [PHY_REG_ADDR_W-1:0] issue0_pdest;
    begin
      dispatch_entry_ready_with_issue0 =
          dispatch_fire && dispatch_bypass_allowed &&
          (src1_ready ||
           (issue0_forward &&
            (src1_preg == issue0_pdest) &&
            (src1_preg != {PHY_REG_ADDR_W{1'b0}})) ||
           wakeup_match(src1_preg,
                        wakeup0_valid_i, wakeup0_pdest_i,
                        wakeup1_valid_i, wakeup1_pdest_i)) &&
          (src2_ready ||
           (issue0_forward &&
            (src2_preg == issue0_pdest) &&
            (src2_preg != {PHY_REG_ADDR_W{1'b0}})) ||
           wakeup_match(src2_preg,
                        wakeup0_valid_i, wakeup0_pdest_i,
                        wakeup1_valid_i, wakeup1_pdest_i));
    end
  endfunction

  function dispatch_entry_depends_on_issue0;
    input dispatch_fire;
    input dispatch_bypass_allowed;
    input src1_ready;
    input [PHY_REG_ADDR_W-1:0] src1_preg;
    input src2_ready;
    input [PHY_REG_ADDR_W-1:0] src2_preg;
    input issue0_forward;
    input [PHY_REG_ADDR_W-1:0] issue0_pdest;
    begin
      dispatch_entry_depends_on_issue0 =
          dispatch_fire && dispatch_bypass_allowed && issue0_forward &&
          (((!src1_ready) && (src1_preg == issue0_pdest) &&
            (src1_preg != {PHY_REG_ADDR_W{1'b0}})) ||
           ((!src2_ready) && (src2_preg == issue0_pdest) &&
            (src2_preg != {PHY_REG_ADDR_W{1'b0}})));
    end
  endfunction

  wire dispatch0_mem_w = ctrl_is_mem(dispatch0_ctrl_i[`CTRL_LOAD_BIT],
                                     dispatch0_ctrl_i[`CTRL_STORE_BIT]);
  wire dispatch1_mem_w = ctrl_is_mem(dispatch1_ctrl_i[`CTRL_LOAD_BIT],
                                     dispatch1_ctrl_i[`CTRL_STORE_BIT]);
  wire pending_load0_real_w =
      pending_load0_valid_i &&
      (pending_load0_pdest_i != {PHY_REG_ADDR_W{1'b0}});
  wire pending_load1_real_w =
      pending_load1_valid_i &&
      (pending_load1_pdest_i != {PHY_REG_ADDR_W{1'b0}});
  always @(*) begin
    queued_store_valid_r = 1'b0;
    for (store_scan_i = 0; store_scan_i < ENTRY_COUNT;
         store_scan_i = store_scan_i + 1) begin
      queued_store_valid_r = queued_store_valid_r ||
                             (valid_q[store_scan_i] &&
                              ctrl_q[store_scan_i][`CTRL_STORE_BIT]);
    end
  end

  wire dispatch0_load_bypass_w =
      dispatch0_ctrl_i[`CTRL_LOAD_BIT] && !dispatch0_ctrl_i[`CTRL_STORE_BIT] &&
      !queued_store_valid_r;
  wire dispatch0_ret_bypass_w =
      dispatch0_ctrl_i[`CTRL_JALR_BIT] &&
      (dispatch0_inst_i[11:7] == 5'd0) &&
      ((dispatch0_inst_i[19:15] == 5'd1) ||
       (dispatch0_inst_i[19:15] == 5'd5)) &&
      (dispatch0_inst_i[31:20] == 12'h000);
  wire dispatch0_control_w =
      ctrl_is_control(dispatch0_ctrl_i[`CTRL_BRANCH_BIT],
                      dispatch0_ctrl_i[`CTRL_JAL_BIT],
                      dispatch0_ctrl_i[`CTRL_JALR_BIT],
                      dispatch0_ctrl_i[`CTRL_ECALL_BIT],
                      dispatch0_ctrl_i[`CTRL_EBREAK_BIT],
                      dispatch0_ctrl_i[`CTRL_SYSTEM_BIT],
                      dispatch0_ctrl_i[`CTRL_MRET_BIT],
                      dispatch0_ctrl_i[`CTRL_WFI_BIT]);
  wire dispatch0_jal_bypass_w =
      dispatch0_ctrl_i[`CTRL_JAL_BIT] &&
      !dispatch0_ctrl_i[`CTRL_BRANCH_BIT] &&
      !dispatch0_ctrl_i[`CTRL_JALR_BIT] &&
      !dispatch0_mem_w &&
      !dispatch1_valid_i;
  wire dispatch1_control_w =
      ctrl_is_control(dispatch1_ctrl_i[`CTRL_BRANCH_BIT],
                      dispatch1_ctrl_i[`CTRL_JAL_BIT],
                      dispatch1_ctrl_i[`CTRL_JALR_BIT],
                      dispatch1_ctrl_i[`CTRL_ECALL_BIT],
                      dispatch1_ctrl_i[`CTRL_EBREAK_BIT],
                      dispatch1_ctrl_i[`CTRL_SYSTEM_BIT],
                      dispatch1_ctrl_i[`CTRL_MRET_BIT],
                      dispatch1_ctrl_i[`CTRL_WFI_BIT]);
  wire dispatch0_control_bypass_block_w =
      dispatch0_control_w &&
      !dispatch0_ctrl_i[`CTRL_BRANCH_BIT] &&
      !dispatch0_ret_bypass_w &&
      !dispatch0_jal_bypass_w;
  wire dispatch0_bypass_allowed_w =
      (!dispatch0_mem_w || dispatch0_load_bypass_w) &&
      !dispatch0_control_bypass_block_w;
  wire dispatch0_jal_issue1_bypass_w =
      dispatch0_jal_bypass_w;
  wire dispatch0_issue1_bypass_allowed_w =
      dispatch0_bypass_allowed_w || dispatch0_jal_issue1_bypass_w;
  wire dispatch1_branch_bypass_w =
      dispatch1_ctrl_i[`CTRL_BRANCH_BIT] && !dispatch0_control_w &&
      !dispatch0_mem_w;
  wire dispatch1_jal_bypass_w =
      dispatch1_ctrl_i[`CTRL_JAL_BIT] && !dispatch0_control_w &&
      !dispatch0_mem_w;
  wire dispatch1_load_bypass_w =
      dispatch1_ctrl_i[`CTRL_LOAD_BIT] &&
      !dispatch1_ctrl_i[`CTRL_STORE_BIT] &&
      !queued_store_valid_r &&
      (!dispatch0_mem_w || dispatch0_load_bypass_w);
  wire dispatch1_optional_bypass_w =
      dispatch1_optional_i && !dispatch1_control_w &&
      (!dispatch1_mem_w || dispatch1_load_bypass_w);
  wire dispatch1_bypass_allowed_w =
      (!dispatch1_mem_w || dispatch1_load_bypass_w) &&
      ((!dispatch1_control_w && !dispatch0_control_w) ||
       dispatch1_branch_bypass_w || dispatch1_jal_bypass_w ||
       dispatch1_optional_bypass_w);
  wire dispatch0_entry_ready_w =
      dispatch0_fire_w && dispatch0_bypass_allowed_w &&
      !(issue_mem_block_i && dispatch0_mem_w) &&
      (dispatch0_src1_ready_i ||
       wakeup_match(dispatch0_src1_preg_i,
                    wakeup0_valid_i, wakeup0_pdest_i,
                    wakeup1_valid_i, wakeup1_pdest_i)) &&
      (dispatch0_src2_ready_i ||
       wakeup_match(dispatch0_src2_preg_i,
                    wakeup0_valid_i, wakeup0_pdest_i,
                    wakeup1_valid_i, wakeup1_pdest_i));
  wire dispatch1_entry_ready_w =
      dispatch1_fire_w && dispatch1_bypass_allowed_w &&
      !(issue_mem_block_i && dispatch1_mem_w) &&
      (dispatch1_src1_ready_i ||
       wakeup_match(dispatch1_src1_preg_i,
                    wakeup0_valid_i, wakeup0_pdest_i,
                    wakeup1_valid_i, wakeup1_pdest_i)) &&
      (dispatch1_src2_ready_i ||
       wakeup_match(dispatch1_src2_preg_i,
                    wakeup0_valid_i, wakeup0_pdest_i,
                    wakeup1_valid_i, wakeup1_pdest_i));
  always @(*) begin
    issue0_found_r = 1'b0;
    issue1_found_r = 1'b0;
    issue0_dispatch0_r = 1'b0;
    issue0_dispatch1_r = 1'b0;
    issue1_dispatch0_r = 1'b0;
    issue1_dispatch1_r = 1'b0;
    issue0_mem_r = 1'b0;
    issue0_load_r = 1'b0;
    issue0_forward_r = 1'b0;
    issue0_pdest_r = {PHY_REG_ADDR_W{1'b0}};
    dispatch0_entry_ready_for_issue1_r = 1'b0;
    dispatch1_entry_ready_for_issue1_r = 1'b0;
    issue1_depends_on_issue0_r = 1'b0;
    older_store_seen_r = 1'b0;
    older_valid_seen_r = 1'b0;
    pending_load_branch_dep_r = 1'b0;
    load_branch_fast_valid_r = 1'b0;
    load_branch_fast_rob_idx_r = {ROB_INDEX_W{1'b0}};
    load_branch_fast_pc_r = {`XLEN{1'b0}};
    load_branch_fast_next_pc_r = {`XLEN{1'b0}};
    load_branch_fast_imm_r = {`XLEN{1'b0}};
    load_branch_fast_cmp_op_r = 3'b000;
    load_branch_fast_src1_preg_r = {PHY_REG_ADDR_W{1'b0}};
    load_branch_fast_src2_preg_r = {PHY_REG_ADDR_W{1'b0}};
    load_branch_fast_wait_load0_r = 1'b0;
    load_branch_fast_wait_load1_r = 1'b0;
    src1_load0_match_r = 1'b0;
    src1_load1_match_r = 1'b0;
    src2_load0_match_r = 1'b0;
    src2_load1_match_r = 1'b0;
    branch_src1_fast_ready_r = 1'b0;
    branch_src2_fast_ready_r = 1'b0;
    entry_load_r = 1'b0;
    entry_store_r = 1'b0;
    entry_mem_order_block_r = 1'b0;
    issue0_idx_r = {ENTRY_INDEX_W{1'b0}};
    issue1_idx_r = {ENTRY_INDEX_W{1'b0}};
    for (scan_i = 0; scan_i < ENTRY_COUNT; scan_i = scan_i + 1) begin
      entry_load_r = ctrl_q[scan_i][`CTRL_LOAD_BIT];
      entry_store_r = ctrl_q[scan_i][`CTRL_STORE_BIT];
      entry_mem_order_block_r =
          (entry_load_r && older_store_seen_r) ||
          (entry_store_r && older_valid_seen_r);
      src1_load0_match_r =
          valid_q[scan_i] &&
          !src1_ready_q[scan_i] &&
          pending_load0_real_w &&
          (src1_preg_q[scan_i] == pending_load0_pdest_i);
      src1_load1_match_r =
          valid_q[scan_i] &&
          !src1_ready_q[scan_i] &&
          pending_load1_real_w &&
          (src1_preg_q[scan_i] == pending_load1_pdest_i);
      src2_load0_match_r =
          valid_q[scan_i] &&
          !src2_ready_q[scan_i] &&
          pending_load0_real_w &&
          (src2_preg_q[scan_i] == pending_load0_pdest_i);
      src2_load1_match_r =
          valid_q[scan_i] &&
          !src2_ready_q[scan_i] &&
          pending_load1_real_w &&
          (src2_preg_q[scan_i] == pending_load1_pdest_i);
      branch_src1_fast_ready_r =
          src1_ready_q[scan_i] ||
          src1_load0_match_r || src1_load1_match_r ||
          wakeup_match(src1_preg_q[scan_i],
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      branch_src2_fast_ready_r =
          src2_ready_q[scan_i] ||
          src2_load0_match_r || src2_load1_match_r ||
          wakeup_match(src2_preg_q[scan_i],
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      pending_load_branch_dep_r = pending_load_branch_dep_r ||
          (valid_q[scan_i] &&
           ctrl_q[scan_i][`CTRL_BRANCH_BIT] &&
           (((!src1_ready_q[scan_i]) &&
             ((pending_load0_real_w &&
               (src1_preg_q[scan_i] == pending_load0_pdest_i)) ||
              (pending_load1_real_w &&
               (src1_preg_q[scan_i] == pending_load1_pdest_i)))) ||
            ((!src2_ready_q[scan_i]) &&
             ((pending_load0_real_w &&
               (src2_preg_q[scan_i] == pending_load0_pdest_i)) ||
              (pending_load1_real_w &&
               (src2_preg_q[scan_i] == pending_load1_pdest_i))))));
      if (!load_branch_fast_valid_r &&
          valid_q[scan_i] &&
          ctrl_q[scan_i][`CTRL_BRANCH_BIT] &&
          (src1_load0_match_r || src1_load1_match_r ||
           src2_load0_match_r || src2_load1_match_r) &&
          branch_src1_fast_ready_r && branch_src2_fast_ready_r) begin
        load_branch_fast_valid_r = 1'b1;
        load_branch_fast_rob_idx_r = rob_idx_q[scan_i];
        load_branch_fast_pc_r = pc_q[scan_i];
        load_branch_fast_next_pc_r = next_pc_q[scan_i];
        load_branch_fast_imm_r = imm_q[scan_i];
        load_branch_fast_cmp_op_r =
            ctrl_q[scan_i][`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB];
        load_branch_fast_src1_preg_r = src1_preg_q[scan_i];
        load_branch_fast_src2_preg_r = src2_preg_q[scan_i];
        load_branch_fast_wait_load0_r =
            src1_load0_match_r || src2_load0_match_r;
        load_branch_fast_wait_load1_r =
            src1_load1_match_r || src2_load1_match_r;
      end
      entry_ready_r[scan_i] = valid_q[scan_i] &&
                              !(issue_mem_block_i &&
                                ctrl_is_mem(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                                            ctrl_q[scan_i][`CTRL_STORE_BIT])) &&
                              !entry_mem_order_block_r &&
                              (src1_ready_q[scan_i] ||
                               wakeup_match(src1_preg_q[scan_i],
                                            wakeup0_valid_i, wakeup0_pdest_i,
                                            wakeup1_valid_i, wakeup1_pdest_i)) &&
                              (src2_ready_q[scan_i] ||
                               wakeup_match(src2_preg_q[scan_i],
                                            wakeup0_valid_i, wakeup0_pdest_i,
                                            wakeup1_valid_i, wakeup1_pdest_i));
      if (entry_ready_r[scan_i]) begin
        if (!issue0_found_r) begin
          issue0_found_r = 1'b1;
          issue0_idx_r = scan_i[ENTRY_INDEX_W-1:0];
          issue0_mem_r = ctrl_is_mem(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                                     ctrl_q[scan_i][`CTRL_STORE_BIT]);
          issue0_load_r = ctrl_q[scan_i][`CTRL_LOAD_BIT];
          issue0_forward_r =
              ctrl_can_forward(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                               ctrl_q[scan_i][`CTRL_STORE_BIT],
                               ctrl_q[scan_i][`CTRL_BRANCH_BIT],
                               ctrl_q[scan_i][`CTRL_JAL_BIT],
                               ctrl_q[scan_i][`CTRL_JALR_BIT],
                               ctrl_q[scan_i][`CTRL_ECALL_BIT],
                               ctrl_q[scan_i][`CTRL_EBREAK_BIT],
                               ctrl_q[scan_i][`CTRL_SYSTEM_BIT],
                               ctrl_q[scan_i][`CTRL_MRET_BIT],
                               ctrl_q[scan_i][`CTRL_WFI_BIT],
                               ctrl_q[scan_i][`CTRL_MULDIV_BIT],
                               ctrl_q[scan_i][`CTRL_BITMANIP_BIT] &&
                               is_clmul_inst(inst_q[scan_i])) &&
                             (pdest_q[scan_i] != {PHY_REG_ADDR_W{1'b0}});
          issue0_pdest_r = pdest_q[scan_i];
        end else if (!issue1_found_r &&
                     !ctrl_q[scan_i][`CTRL_STORE_BIT] &&
                     !(issue0_mem_r &&
                       ctrl_is_mem(ctrl_q[scan_i][`CTRL_LOAD_BIT],
                                   ctrl_q[scan_i][`CTRL_STORE_BIT]) &&
                       !(issue0_load_r &&
                         ctrl_q[scan_i][`CTRL_LOAD_BIT]))) begin
          issue1_found_r = 1'b1;
          issue1_idx_r = scan_i[ENTRY_INDEX_W-1:0];
          issue1_depends_on_issue0_r = 1'b0;
        end
      end
      older_store_seen_r = older_store_seen_r ||
                           (valid_q[scan_i] &&
                            ctrl_q[scan_i][`CTRL_STORE_BIT]);
      older_valid_seen_r = older_valid_seen_r || valid_q[scan_i];
    end

    // 当前普通 ALU、可直接发射 load/ret、ready lane1 branch/JAL dispatch 已经在 ROB/rename 边界完成分配；把它作为
    // IQ 队尾的虚拟 entry 参与同拍 issue，可消除空队列 refill 的一拍气泡。
    // 其他控制、store 和 lane1 memory uop 保持原路径，避免同拍副作用反向影响 dispatch ready。
    if (issue0_found_r) begin
      dispatch0_entry_ready_for_issue1_r =
          dispatch_entry_ready_with_issue0(
              dispatch0_fire_w, dispatch0_issue1_bypass_allowed_w,
              dispatch0_src1_ready_i, dispatch0_src1_preg_i,
              dispatch0_src2_ready_i, dispatch0_src2_preg_i,
              issue0_forward_r, issue0_pdest_r);
      dispatch1_entry_ready_for_issue1_r =
          dispatch_entry_ready_with_issue0(
              dispatch1_fire_w, dispatch1_bypass_allowed_w,
              dispatch1_src1_ready_i, dispatch1_src1_preg_i,
              dispatch1_src2_ready_i, dispatch1_src2_preg_i,
              issue0_forward_r, issue0_pdest_r);
    end

    if (dispatch0_entry_ready_w ||
        dispatch0_entry_ready_for_issue1_r) begin
      if (!issue0_found_r) begin
        issue0_found_r = 1'b1;
        issue0_dispatch0_r = 1'b1;
        issue0_mem_r = dispatch0_mem_w;
        issue0_load_r = dispatch0_ctrl_i[`CTRL_LOAD_BIT];
        issue0_forward_r =
            ctrl_can_forward(dispatch0_ctrl_i[`CTRL_LOAD_BIT],
                             dispatch0_ctrl_i[`CTRL_STORE_BIT],
                             dispatch0_ctrl_i[`CTRL_BRANCH_BIT],
                             dispatch0_ctrl_i[`CTRL_JAL_BIT],
                             dispatch0_ctrl_i[`CTRL_JALR_BIT],
                             dispatch0_ctrl_i[`CTRL_ECALL_BIT],
                             dispatch0_ctrl_i[`CTRL_EBREAK_BIT],
                             dispatch0_ctrl_i[`CTRL_SYSTEM_BIT],
                             dispatch0_ctrl_i[`CTRL_MRET_BIT],
                             dispatch0_ctrl_i[`CTRL_WFI_BIT],
                             dispatch0_ctrl_i[`CTRL_MULDIV_BIT],
                             dispatch0_ctrl_i[`CTRL_BITMANIP_BIT] &&
                             is_clmul_inst(dispatch0_inst_i)) &&
                           (dispatch0_pdest_i != {PHY_REG_ADDR_W{1'b0}});
        issue0_pdest_r = dispatch0_pdest_i;
        dispatch1_entry_ready_for_issue1_r =
            dispatch_entry_ready_with_issue0(
                dispatch1_fire_w, dispatch1_bypass_allowed_w,
                dispatch1_src1_ready_i, dispatch1_src1_preg_i,
                dispatch1_src2_ready_i, dispatch1_src2_preg_i,
                issue0_forward_r, issue0_pdest_r);
      end else if (!issue1_found_r && dispatch0_entry_ready_for_issue1_r &&
                   !dispatch0_ctrl_i[`CTRL_STORE_BIT] &&
                   !(issue0_mem_r &&
                     ((dispatch0_mem_w &&
                       !(issue0_load_r &&
                         dispatch0_ctrl_i[`CTRL_LOAD_BIT])) ||
                      dispatch0_jal_issue1_bypass_w)) &&
                   (!dispatch0_jal_issue1_bypass_w || issue0_forward_r)) begin
        issue1_found_r = 1'b1;
        issue1_dispatch0_r = 1'b1;
        issue1_depends_on_issue0_r =
            !dispatch0_entry_ready_w &&
            dispatch_entry_depends_on_issue0(
                dispatch0_fire_w, dispatch0_issue1_bypass_allowed_w,
                dispatch0_src1_ready_i, dispatch0_src1_preg_i,
                dispatch0_src2_ready_i, dispatch0_src2_preg_i,
                issue0_forward_r, issue0_pdest_r);
      end
    end

    if (dispatch1_entry_ready_w ||
        dispatch1_entry_ready_for_issue1_r) begin
      if (!issue0_found_r) begin
        issue0_found_r = 1'b1;
        issue0_dispatch1_r = 1'b1;
        issue0_mem_r = dispatch1_mem_w;
        issue0_load_r = dispatch1_ctrl_i[`CTRL_LOAD_BIT];
        issue0_forward_r =
            ctrl_can_forward(dispatch1_ctrl_i[`CTRL_LOAD_BIT],
                             dispatch1_ctrl_i[`CTRL_STORE_BIT],
                             dispatch1_ctrl_i[`CTRL_BRANCH_BIT],
                             dispatch1_ctrl_i[`CTRL_JAL_BIT],
                             dispatch1_ctrl_i[`CTRL_JALR_BIT],
                             dispatch1_ctrl_i[`CTRL_ECALL_BIT],
                             dispatch1_ctrl_i[`CTRL_EBREAK_BIT],
                             dispatch1_ctrl_i[`CTRL_SYSTEM_BIT],
                             dispatch1_ctrl_i[`CTRL_MRET_BIT],
                             dispatch1_ctrl_i[`CTRL_WFI_BIT],
                             dispatch1_ctrl_i[`CTRL_MULDIV_BIT],
                             dispatch1_ctrl_i[`CTRL_BITMANIP_BIT] &&
                             is_clmul_inst(dispatch1_inst_i)) &&
                           (dispatch1_pdest_i != {PHY_REG_ADDR_W{1'b0}});
        issue0_pdest_r = dispatch1_pdest_i;
      end else if (!issue1_found_r &&
                   (dispatch1_entry_ready_w ||
                    dispatch1_entry_ready_for_issue1_r) &&
                   !dispatch1_ctrl_i[`CTRL_STORE_BIT] &&
                   !(issue0_mem_r && dispatch1_mem_w &&
                     !(issue0_load_r &&
                       dispatch1_ctrl_i[`CTRL_LOAD_BIT]))) begin
        issue1_found_r = 1'b1;
        issue1_dispatch1_r = 1'b1;
        issue1_depends_on_issue0_r =
            !dispatch1_entry_ready_w &&
            dispatch_entry_depends_on_issue0(
                dispatch1_fire_w, dispatch1_bypass_allowed_w,
                dispatch1_src1_ready_i, dispatch1_src1_preg_i,
                dispatch1_src2_ready_i, dispatch1_src2_preg_i,
                issue0_forward_r, issue0_pdest_r);
      end
    end
  end

  assign dispatch0_ready_o = (free_slots_w != {ENTRY_COUNT_W{1'b0}});
  assign dispatch1_ready_o = (free_slots_w > {{(ENTRY_COUNT_W-1){1'b0}}, dispatch0_fire_w});

  assign issue0_valid_o = issue0_found_r;
  assign issue0_pc_o = issue0_dispatch0_r ? dispatch0_pc_i :
                       issue0_dispatch1_r ? dispatch1_pc_i :
                       pc_q[issue0_idx_r];
  assign issue0_next_pc_o = issue0_dispatch0_r ? dispatch0_next_pc_i :
                            issue0_dispatch1_r ? dispatch1_next_pc_i :
                            next_pc_q[issue0_idx_r];
  assign issue0_inst_o = issue0_dispatch0_r ? dispatch0_inst_i :
                         issue0_dispatch1_r ? dispatch1_inst_i :
                         inst_q[issue0_idx_r];
  assign issue0_ctrl_o = issue0_dispatch0_r ? dispatch0_ctrl_i :
                         issue0_dispatch1_r ? dispatch1_ctrl_i :
                         ctrl_q[issue0_idx_r];
  assign issue0_rob_idx_o = issue0_dispatch0_r ? dispatch0_rob_idx_i :
                            issue0_dispatch1_r ? dispatch1_rob_idx_i :
                            rob_idx_q[issue0_idx_r];
  assign issue0_src1_preg_o = issue0_dispatch0_r ? dispatch0_src1_preg_i :
                              issue0_dispatch1_r ? dispatch1_src1_preg_i :
                              src1_preg_q[issue0_idx_r];
  assign issue0_src2_preg_o = issue0_dispatch0_r ? dispatch0_src2_preg_i :
                              issue0_dispatch1_r ? dispatch1_src2_preg_i :
                              src2_preg_q[issue0_idx_r];
  assign issue0_pdest_o = issue0_dispatch0_r ? dispatch0_pdest_i :
                          issue0_dispatch1_r ? dispatch1_pdest_i :
                          pdest_q[issue0_idx_r];
  assign issue0_imm_o = issue0_dispatch0_r ? dispatch0_imm_i :
                        issue0_dispatch1_r ? dispatch1_imm_i :
                        imm_q[issue0_idx_r];

  assign issue1_valid_o =
      issue1_found_r && (!issue1_depends_on_issue0_r || issue0_fire_w);
  assign issue1_pc_o = issue1_dispatch0_r ? dispatch0_pc_i :
                       issue1_dispatch1_r ? dispatch1_pc_i :
                       pc_q[issue1_idx_r];
  assign issue1_next_pc_o = issue1_dispatch0_r ? dispatch0_next_pc_i :
                            issue1_dispatch1_r ? dispatch1_next_pc_i :
                            next_pc_q[issue1_idx_r];
  assign issue1_inst_o = issue1_dispatch0_r ? dispatch0_inst_i :
                         issue1_dispatch1_r ? dispatch1_inst_i :
                         inst_q[issue1_idx_r];
  assign issue1_ctrl_o = issue1_dispatch0_r ? dispatch0_ctrl_i :
                         issue1_dispatch1_r ? dispatch1_ctrl_i :
                         ctrl_q[issue1_idx_r];
  assign issue1_rob_idx_o = issue1_dispatch0_r ? dispatch0_rob_idx_i :
                            issue1_dispatch1_r ? dispatch1_rob_idx_i :
                            rob_idx_q[issue1_idx_r];
  assign issue1_src1_preg_o = issue1_dispatch0_r ? dispatch0_src1_preg_i :
                              issue1_dispatch1_r ? dispatch1_src1_preg_i :
                              src1_preg_q[issue1_idx_r];
  assign issue1_src2_preg_o = issue1_dispatch0_r ? dispatch0_src2_preg_i :
                              issue1_dispatch1_r ? dispatch1_src2_preg_i :
                              src2_preg_q[issue1_idx_r];
  assign issue1_pdest_o = issue1_dispatch0_r ? dispatch0_pdest_i :
                          issue1_dispatch1_r ? dispatch1_pdest_i :
                          pdest_q[issue1_idx_r];
  assign issue1_imm_o = issue1_dispatch0_r ? dispatch0_imm_i :
                        issue1_dispatch1_r ? dispatch1_imm_i :
                        imm_q[issue1_idx_r];

  assign count_o = count_q;
  assign empty_o = (count_q == {ENTRY_COUNT_W{1'b0}});
  assign pending_load_branch_dep_o = pending_load_branch_dep_r;
  assign load_branch_fast_valid_o = load_branch_fast_valid_r;
  assign load_branch_fast_rob_idx_o = load_branch_fast_rob_idx_r;
  assign load_branch_fast_pc_o = load_branch_fast_pc_r;
  assign load_branch_fast_next_pc_o = load_branch_fast_next_pc_r;
  assign load_branch_fast_imm_o = load_branch_fast_imm_r;
  assign load_branch_fast_cmp_op_o = load_branch_fast_cmp_op_r;
  assign load_branch_fast_src1_preg_o = load_branch_fast_src1_preg_r;
  assign load_branch_fast_src2_preg_o = load_branch_fast_src2_preg_r;
  assign load_branch_fast_wait_load0_o = load_branch_fast_wait_load0_r;
  assign load_branch_fast_wait_load1_o = load_branch_fast_wait_load1_r;
  assign full_o = (count_q == ENTRY_COUNT[ENTRY_COUNT_W-1:0]);

  wire dispatch0_issue_fire_w =
      (issue0_fire_w && issue0_dispatch0_r) ||
      (issue1_fire_w && issue1_dispatch0_r);
  wire dispatch1_issue_fire_w =
      (issue0_fire_w && issue0_dispatch1_r) ||
      (issue1_fire_w && issue1_dispatch1_r);
  wire issue0_queue_fire_w =
      issue0_fire_w && !issue0_dispatch0_r && !issue0_dispatch1_r;
  wire issue1_queue_fire_w =
      issue1_fire_w && !issue1_dispatch0_r && !issue1_dispatch1_r;

  always @(*) begin
    write_i = 0;
    count_next_r = {ENTRY_COUNT_W{1'b0}};
    for (compact_i = 0; compact_i < ENTRY_COUNT; compact_i = compact_i + 1) begin
      valid_next_r[compact_i] = 1'b0;
      pc_next_r[compact_i] = {`XLEN{1'b0}};
      next_pc_next_r[compact_i] = {`XLEN{1'b0}};
      inst_next_r[compact_i] = {`INST_W{1'b0}};
      ctrl_next_r[compact_i] = {`CTRL_BUS_W{1'b0}};
      rob_idx_next_r[compact_i] = {ROB_INDEX_W{1'b0}};
      src1_preg_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      src1_ready_next_r[compact_i] = 1'b0;
      src2_preg_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      src2_ready_next_r[compact_i] = 1'b0;
      pdest_next_r[compact_i] = {PHY_REG_ADDR_W{1'b0}};
      imm_next_r[compact_i] = {`XLEN{1'b0}};
    end

    for (compact_i = 0; compact_i < ENTRY_COUNT; compact_i = compact_i + 1) begin
      if (valid_q[compact_i] &&
          !(issue0_queue_fire_w &&
            (compact_i[ENTRY_INDEX_W-1:0] == issue0_idx_r)) &&
          !(issue1_queue_fire_w &&
            (compact_i[ENTRY_INDEX_W-1:0] == issue1_idx_r))) begin
        valid_next_r[write_i] = 1'b1;
        pc_next_r[write_i] = pc_q[compact_i];
        next_pc_next_r[write_i] = next_pc_q[compact_i];
        inst_next_r[write_i] = inst_q[compact_i];
        ctrl_next_r[write_i] = ctrl_q[compact_i];
        rob_idx_next_r[write_i] = rob_idx_q[compact_i];
        src1_preg_next_r[write_i] = src1_preg_q[compact_i];
        src1_ready_next_r[write_i] =
            src1_ready_q[compact_i] ||
            wakeup_match(src1_preg_q[compact_i],
                         wakeup0_valid_i, wakeup0_pdest_i,
                         wakeup1_valid_i, wakeup1_pdest_i);
        src2_preg_next_r[write_i] = src2_preg_q[compact_i];
        src2_ready_next_r[write_i] =
            src2_ready_q[compact_i] ||
            wakeup_match(src2_preg_q[compact_i],
                         wakeup0_valid_i, wakeup0_pdest_i,
                         wakeup1_valid_i, wakeup1_pdest_i);
        pdest_next_r[write_i] = pdest_q[compact_i];
        imm_next_r[write_i] = imm_q[compact_i];
        write_i = write_i + 1;
      end
    end

    if (dispatch0_fire_w && !dispatch0_issue_fire_w) begin
      valid_next_r[write_i] = 1'b1;
      pc_next_r[write_i] = dispatch0_pc_i;
      next_pc_next_r[write_i] = dispatch0_next_pc_i;
      inst_next_r[write_i] = dispatch0_inst_i;
      ctrl_next_r[write_i] = dispatch0_ctrl_i;
      rob_idx_next_r[write_i] = dispatch0_rob_idx_i;
      src1_preg_next_r[write_i] = dispatch0_src1_preg_i;
      src1_ready_next_r[write_i] =
          dispatch0_src1_ready_i ||
          wakeup_match(dispatch0_src1_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      src2_preg_next_r[write_i] = dispatch0_src2_preg_i;
      src2_ready_next_r[write_i] =
          dispatch0_src2_ready_i ||
          wakeup_match(dispatch0_src2_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      pdest_next_r[write_i] = dispatch0_pdest_i;
      imm_next_r[write_i] = dispatch0_imm_i;
      write_i = write_i + 1;
    end

    if (dispatch1_fire_w && !dispatch1_issue_fire_w) begin
      valid_next_r[write_i] = 1'b1;
      pc_next_r[write_i] = dispatch1_pc_i;
      next_pc_next_r[write_i] = dispatch1_next_pc_i;
      inst_next_r[write_i] = dispatch1_inst_i;
      ctrl_next_r[write_i] = dispatch1_ctrl_i;
      rob_idx_next_r[write_i] = dispatch1_rob_idx_i;
      src1_preg_next_r[write_i] = dispatch1_src1_preg_i;
      src1_ready_next_r[write_i] =
          dispatch1_src1_ready_i ||
          wakeup_match(dispatch1_src1_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      src2_preg_next_r[write_i] = dispatch1_src2_preg_i;
      src2_ready_next_r[write_i] =
          dispatch1_src2_ready_i ||
          wakeup_match(dispatch1_src2_preg_i,
                       wakeup0_valid_i, wakeup0_pdest_i,
                       wakeup1_valid_i, wakeup1_pdest_i);
      pdest_next_r[write_i] = dispatch1_pdest_i;
      imm_next_r[write_i] = dispatch1_imm_i;
      write_i = write_i + 1;
    end

    count_next_r = write_i[ENTRY_COUNT_W-1:0];
  end

  always @(posedge clk) begin
    if (rst || flush_i) begin
      count_q <= {ENTRY_COUNT_W{1'b0}};
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        valid_q[reset_i] <= 1'b0;
        pc_q[reset_i] <= {`XLEN{1'b0}};
        next_pc_q[reset_i] <= {`XLEN{1'b0}};
        inst_q[reset_i] <= {`INST_W{1'b0}};
        ctrl_q[reset_i] <= {`CTRL_BUS_W{1'b0}};
        rob_idx_q[reset_i] <= {ROB_INDEX_W{1'b0}};
        src1_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        src1_ready_q[reset_i] <= 1'b0;
        src2_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        src2_ready_q[reset_i] <= 1'b0;
        pdest_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        imm_q[reset_i] <= {`XLEN{1'b0}};
        checkpoint_valid_q[reset_i] <= 1'b0;
        checkpoint_pc_q[reset_i] <= {`XLEN{1'b0}};
        checkpoint_next_pc_q[reset_i] <= {`XLEN{1'b0}};
        checkpoint_inst_q[reset_i] <= {`INST_W{1'b0}};
        checkpoint_ctrl_q[reset_i] <= {`CTRL_BUS_W{1'b0}};
        checkpoint_rob_idx_q[reset_i] <= {ROB_INDEX_W{1'b0}};
        checkpoint_src1_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        checkpoint_src1_ready_q[reset_i] <= 1'b0;
        checkpoint_src2_preg_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        checkpoint_src2_ready_q[reset_i] <= 1'b0;
        checkpoint_pdest_q[reset_i] <= {PHY_REG_ADDR_W{1'b0}};
        checkpoint_imm_q[reset_i] <= {`XLEN{1'b0}};
      end
      checkpoint_count_q <= {ENTRY_COUNT_W{1'b0}};
    end else if (checkpoint_restore_i) begin
      count_q <= checkpoint_count_q;
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        valid_q[reset_i] <= checkpoint_valid_q[reset_i];
        pc_q[reset_i] <= checkpoint_pc_q[reset_i];
        next_pc_q[reset_i] <= checkpoint_next_pc_q[reset_i];
        inst_q[reset_i] <= checkpoint_inst_q[reset_i];
        ctrl_q[reset_i] <= checkpoint_ctrl_q[reset_i];
        rob_idx_q[reset_i] <= checkpoint_rob_idx_q[reset_i];
        src1_preg_q[reset_i] <= checkpoint_src1_preg_q[reset_i];
        src1_ready_q[reset_i] <= checkpoint_src1_ready_q[reset_i];
        src2_preg_q[reset_i] <= checkpoint_src2_preg_q[reset_i];
        src2_ready_q[reset_i] <= checkpoint_src2_ready_q[reset_i];
        pdest_q[reset_i] <= checkpoint_pdest_q[reset_i];
        imm_q[reset_i] <= checkpoint_imm_q[reset_i];
      end
    end else if (checkpoint_capture_i) begin
      checkpoint_count_q <= count_q;
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        checkpoint_valid_q[reset_i] <= valid_q[reset_i];
        checkpoint_pc_q[reset_i] <= pc_q[reset_i];
        checkpoint_next_pc_q[reset_i] <= next_pc_q[reset_i];
        checkpoint_inst_q[reset_i] <= inst_q[reset_i];
        checkpoint_ctrl_q[reset_i] <= ctrl_q[reset_i];
        checkpoint_rob_idx_q[reset_i] <= rob_idx_q[reset_i];
        checkpoint_src1_preg_q[reset_i] <= src1_preg_q[reset_i];
        checkpoint_src1_ready_q[reset_i] <= src1_ready_q[reset_i];
        checkpoint_src2_preg_q[reset_i] <= src2_preg_q[reset_i];
        checkpoint_src2_ready_q[reset_i] <= src2_ready_q[reset_i];
        checkpoint_pdest_q[reset_i] <= pdest_q[reset_i];
        checkpoint_imm_q[reset_i] <= imm_q[reset_i];
      end
    end else begin
      count_q <= count_next_r;
      for (reset_i = 0; reset_i < ENTRY_COUNT; reset_i = reset_i + 1) begin
        valid_q[reset_i] <= valid_next_r[reset_i];
        pc_q[reset_i] <= pc_next_r[reset_i];
        next_pc_q[reset_i] <= next_pc_next_r[reset_i];
        inst_q[reset_i] <= inst_next_r[reset_i];
        ctrl_q[reset_i] <= ctrl_next_r[reset_i];
        rob_idx_q[reset_i] <= rob_idx_next_r[reset_i];
        src1_preg_q[reset_i] <= src1_preg_next_r[reset_i];
        src1_ready_q[reset_i] <= src1_ready_next_r[reset_i];
        src2_preg_q[reset_i] <= src2_preg_next_r[reset_i];
        src2_ready_q[reset_i] <= src2_ready_next_r[reset_i];
        pdest_q[reset_i] <= pdest_next_r[reset_i];
        imm_q[reset_i] <= imm_next_r[reset_i];
      end
    end
  end

endmodule
