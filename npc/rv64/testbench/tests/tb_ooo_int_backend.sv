`include "define.v"

module tb_ooo_int_backend;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam FREE_COUNT_W = 7;
  localparam ISSUE_COUNT_W = 4;

  reg clk;
  reg rst;
  reg flush;

  reg dispatch0_valid;
  wire dispatch0_ready;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`INST_W-1:0] dispatch0_inst;
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch0_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rd_arch;
  reg [`XLEN-1:0] dispatch0_imm;

  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch1_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rd_arch;
  reg [`XLEN-1:0] dispatch1_imm;

  reg commit_ready;
  wire commit0_valid;
  wire [`XLEN-1:0] commit0_pc;
  wire [`XLEN-1:0] commit0_next_pc;
  wire [`INST_W-1:0] commit0_inst;
  wire commit0_rd_en;
  wire [`REG_ADDR_W-1:0] commit0_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit0_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit0_new_pdest;
  wire [`XLEN-1:0] commit0_data;
  wire commit0_exception;
  wire [`TRAP_CAUSE_W-1:0] commit0_cause;
  wire [`XLEN-1:0] commit0_tval;

  wire commit1_valid;
  wire [`XLEN-1:0] commit1_pc;
  wire [`XLEN-1:0] commit1_next_pc;
  wire [`INST_W-1:0] commit1_inst;
  wire commit1_rd_en;
  wire [`REG_ADDR_W-1:0] commit1_arch_rd;
  wire [PHY_REG_ADDR_W-1:0] commit1_old_pdest;
  wire [PHY_REG_ADDR_W-1:0] commit1_new_pdest;
  wire [`XLEN-1:0] commit1_data;
  wire commit1_exception;
  wire [`TRAP_CAUSE_W-1:0] commit1_cause;
  wire [`XLEN-1:0] commit1_tval;

  wire [FREE_COUNT_W-1:0] free_count;
  wire [ROB_COUNT_W-1:0] rob_count;
  wire [ISSUE_COUNT_W-1:0] issue_count;
  wire execute0_valid;
  wire execute1_valid;
  wire branch_resolve_valid;
  wire [`XLEN-1:0] branch_resolve_pc;
  wire [`XLEN-1:0] branch_resolve_next_pc;
  wire branch_resolve_misaligned;
  wire dispatch_branch_resolve_valid;
  wire [`XLEN-1:0] dispatch_branch_resolve_pc;
  wire [`XLEN-1:0] dispatch_branch_resolve_next_pc;
  wire dispatch_branch_resolve_misaligned;
  wire mem_req_valid;
  wire mem_req_write;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  wire mem_rsp_ready;
  reg mem_rsp_valid;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;

  wire unused_mem_ready = mem_rsp_ready;

  OooIntBackend dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .checkpoint_capture_i(1'b0),
    .checkpoint_restore_i(1'b0),
    .checkpoint_quiesce_i(1'b0),
    .mem_issue_block_i(1'b0),
    .pending_branch_fast_valid_i(1'b0),
    .pending_branch_fast_pc_i({`XLEN{1'b0}}),
    .recover_gprs_i({(`XLEN * `REG_NUM){1'b0}}),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i('0),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch),
    .dispatch0_rd_arch_i(dispatch0_rd_arch),
    .dispatch0_imm_i(dispatch0_imm),
    .dispatch0_is_fp_i(1'b0),
    .dispatch0_fp_load_i(1'b0),
    .dispatch0_fp_store_i(1'b0),
    .dispatch0_fp_double_i(1'b0),
    .dispatch0_fp_gpr_write_i(1'b0),
    .dispatch0_fp_gpr_src_i(1'b0),
    .dispatch0_fp_fs1_en_i(1'b0),
    .dispatch0_fp_fs2_en_i(1'b0),
    .dispatch0_fp_fs3_en_i(1'b0),
    .dispatch1_is_fp_i(1'b0),
    .dispatch1_fp_load_i(1'b0),
    .dispatch1_fp_store_i(1'b0),
    .dispatch1_fp_double_i(1'b0),
    .dispatch1_fp_gpr_write_i(1'b0),
    .dispatch1_fp_gpr_src_i(1'b0),
    .dispatch1_fp_fs1_en_i(1'b0),
    .dispatch1_fp_fs2_en_i(1'b0),
    .dispatch1_fp_fs3_en_i(1'b0),
    .frm_i(3'b000),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(1'b0),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i('0),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_ctrl_i(dispatch1_ctrl),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch),
    .dispatch1_rd_arch_i(dispatch1_rd_arch),
    .dispatch1_imm_i(dispatch1_imm),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(1'b1),
    .mem_req_write_o(mem_req_write),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(mem_rsp_valid),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i(mem_rsp_rdata),
    .mem_rsp_error_i(mem_rsp_error),
    .mem_rsp_page_fault_i(1'b0),
    .commit_ready_i(commit_ready),
    .commit1_block_i(1'b0),
    .commit0_valid_o(commit0_valid),
    .commit0_pc_o(commit0_pc),
    .commit0_next_pc_o(commit0_next_pc),
    .commit0_inst_o(commit0_inst),
    .commit0_rd_en_o(commit0_rd_en),
    .commit0_arch_rd_o(commit0_arch_rd),
    .commit0_old_pdest_o(commit0_old_pdest),
    .commit0_new_pdest_o(commit0_new_pdest),
    .commit0_data_o(commit0_data),
    .commit0_exception_o(commit0_exception),
    .commit0_cause_o(commit0_cause),
    .commit0_tval_o(commit0_tval),
    .commit1_valid_o(commit1_valid),
    .commit1_pc_o(commit1_pc),
    .commit1_next_pc_o(commit1_next_pc),
    .commit1_inst_o(commit1_inst),
    .commit1_rd_en_o(commit1_rd_en),
    .commit1_arch_rd_o(commit1_arch_rd),
    .commit1_old_pdest_o(commit1_old_pdest),
    .commit1_new_pdest_o(commit1_new_pdest),
    .commit1_data_o(commit1_data),
    .commit1_exception_o(commit1_exception),
    .commit1_cause_o(commit1_cause),
    .commit1_tval_o(commit1_tval),
    .free_count_o(free_count),
    .rob_count_o(rob_count),
	    .issue_count_o(issue_count),
	    .execute0_valid_o(execute0_valid),
	    .execute1_valid_o(execute1_valid),
	    .branch_resolve_valid_o(branch_resolve_valid),
	    .branch_resolve_pc_o(branch_resolve_pc),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned)
	  );

  wire unused_next_pc_w = (|commit0_next_pc) | (|commit1_next_pc) |
                          branch_resolve_valid | (|branch_resolve_pc) |
                          (|branch_resolve_next_pc) |
                          branch_resolve_misaligned |
                          dispatch_branch_resolve_valid |
                          (|dispatch_branch_resolve_pc) |
                          (|dispatch_branch_resolve_next_pc) |
                          dispatch_branch_resolve_misaligned;

  function [`CTRL_BUS_W-1:0] make_alu_ctrl;
    input [1:0] op1_sel;
    input [1:0] op2_sel;
    input [3:0] alu_op;
    input rs1_en;
    input rs2_en;
    input rd_en;
    begin
      make_alu_ctrl = {`CTRL_BUS_W{1'b0}};
      make_alu_ctrl[`CTRL_VALID_BIT] = 1'b1;
      make_alu_ctrl[`CTRL_RS1_EN_BIT] = rs1_en;
      make_alu_ctrl[`CTRL_RS2_EN_BIT] = rs2_en;
      make_alu_ctrl[`CTRL_RD_EN_BIT] = rd_en;
      make_alu_ctrl[`CTRL_OP1_SEL_MSB:`CTRL_OP1_SEL_LSB] = op1_sel;
      make_alu_ctrl[`CTRL_OP2_SEL_MSB:`CTRL_OP2_SEL_LSB] = op2_sel;
      make_alu_ctrl[`CTRL_ALU_OP_MSB:`CTRL_ALU_OP_LSB] = alu_op;
      make_alu_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
      make_alu_ctrl[`CTRL_NEED_WB_BIT] = rd_en;
      make_alu_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = rd_en ? `WB_SEL_ALU : `WB_SEL_NONE;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_store_ctrl;
    input [1:0] mem_size;
    begin
      make_store_ctrl = make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b0);
      make_store_ctrl[`CTRL_STORE_BIT] = 1'b1;
      make_store_ctrl[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = mem_size;
      make_store_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_load_ctrl;
    input [1:0] mem_size;
    input mem_unsigned;
    begin
      make_load_ctrl = make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                     `ALU_OP_ADD, 1'b0, 1'b0, 1'b1);
      make_load_ctrl[`CTRL_LOAD_BIT] = 1'b1;
      make_load_ctrl[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = mem_size;
      make_load_ctrl[`CTRL_MEM_UNSIGNED_BIT] = mem_unsigned;
      make_load_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
      make_load_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_amo_ctrl;
    input [1:0] mem_size;
    input is_lr;
    input is_sc;
    begin
      make_amo_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_ZERO,
                                    `ALU_OP_ADD, 1'b1, !is_lr, 1'b1);
      make_amo_ctrl[`CTRL_LOAD_BIT] = !is_sc;
      make_amo_ctrl[`CTRL_STORE_BIT] = !is_lr;
      make_amo_ctrl[`CTRL_AMO_BIT] = 1'b1;
      make_amo_ctrl[`CTRL_AMO_LR_BIT] = is_lr;
      make_amo_ctrl[`CTRL_AMO_SC_BIT] = is_sc;
      make_amo_ctrl[`CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] = mem_size;
      make_amo_ctrl[`CTRL_NEED_MEM_BIT] = 1'b1;
      make_amo_ctrl[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_LOAD;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_bitmanip_ctrl;
    begin
      make_bitmanip_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2,
                                         `ALU_OP_ADD, 1'b1, 1'b0, 1'b1);
      make_bitmanip_ctrl[`CTRL_BITMANIP_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_bitmanip_op_ctrl;
    begin
      make_bitmanip_op_ctrl = make_bitmanip_ctrl();
      make_bitmanip_op_ctrl[`CTRL_RS2_EN_BIT] = 1'b1;
    end
  endfunction

  function [`INST_W-1:0] inst_op_imm;
    input [6:0] funct7;
    input [4:0] imm5;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_op_imm = {funct7, imm5, rs1, funct3, rd, `OPCODE_OP_IMM};
    end
  endfunction

  function [`INST_W-1:0] inst_op;
    input [6:0] funct7;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_op = {funct7, rs2, rs1, funct3, rd, `OPCODE_OP};
    end
  endfunction

  function [`INST_W-1:0] inst_amo;
    input [4:0] funct5;
    input [4:0] rs2;
    input [4:0] rs1;
    input [2:0] funct3;
    input [4:0] rd;
    begin
      inst_amo = {funct5, 2'b00, rs2, rs1, funct3, rd, `OPCODE_AMO};
    end
  endfunction

  task automatic tb_check64;
    input [1023:0] what;
    input [`XLEN-1:0] got;
    input [`XLEN-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%016x expected=0x%016x",
                 what, got, exp);
      end
    end
  endtask

  function [`XLEN-1:0] ref_clmul;
    input [1:0] op;
    input [`XLEN-1:0] src1;
    input [`XLEN-1:0] src2;
    integer i;
    begin
      ref_clmul = {`XLEN{1'b0}};
      if (op == 2'd0) begin
        for (i = 0; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 << i);
        end
      end else if (op == 2'd1) begin
        for (i = 0; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 >> (63 - i));
        end
      end else begin
        for (i = 1; i < 64; i = i + 1) begin
          if (src2[i])
            ref_clmul = ref_clmul ^ (src1 >> (64 - i));
        end
      end
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_branch_ctrl;
    input [2:0] cmp_op;
    begin
      make_branch_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2,
                                       `ALU_OP_ADD, 1'b1, 1'b1, 1'b0);
      make_branch_ctrl[`CTRL_BRANCH_BIT] = 1'b1;
      make_branch_ctrl[`CTRL_CMP_OP_MSB:`CTRL_CMP_OP_LSB] = cmp_op;
    end
  endfunction

  task automatic clear_dispatch;
    begin
      flush = 1'b0;
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_rs1_arch = 5'd0;
      dispatch0_rs2_arch = 5'd0;
      dispatch0_rd_arch = 5'd0;
      dispatch0_imm = 32'h0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_rs1_arch = 5'd0;
      dispatch1_rs2_arch = 5'd0;
      dispatch1_rd_arch = 5'd0;
      dispatch1_imm = 32'h0;
    end
  endtask

  task automatic reset_dut;
    begin
	      clk = 1'b0;
	      rst = 1'b1;
	      commit_ready = 1'b1;
	      mem_rsp_valid = 1'b0;
	      mem_rsp_rdata = {`XLEN{1'b0}};
	      mem_rsp_error = 1'b0;
	      clear_dispatch();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic set_dispatch0;
    input [`XLEN-1:0] pc;
    input [`CTRL_BUS_W-1:0] ctrl;
    input [`REG_ADDR_W-1:0] rs1;
    input [`REG_ADDR_W-1:0] rs2;
    input [`REG_ADDR_W-1:0] rd;
    input [`XLEN-1:0] imm;
    begin
      dispatch0_valid = 1'b1;
      dispatch0_pc = pc;
      dispatch0_inst = pc;
      dispatch0_ctrl = ctrl;
      dispatch0_rs1_arch = rs1;
      dispatch0_rs2_arch = rs2;
      dispatch0_rd_arch = rd;
      dispatch0_imm = imm;
    end
  endtask

  task automatic set_dispatch1;
    input [`XLEN-1:0] pc;
    input [`CTRL_BUS_W-1:0] ctrl;
    input [`REG_ADDR_W-1:0] rs1;
    input [`REG_ADDR_W-1:0] rs2;
    input [`REG_ADDR_W-1:0] rd;
    input [`XLEN-1:0] imm;
    begin
      dispatch1_valid = 1'b1;
      dispatch1_pc = pc;
      dispatch1_inst = pc;
      dispatch1_ctrl = ctrl;
      dispatch1_rs1_arch = rs1;
      dispatch1_rs2_arch = rs2;
      dispatch1_rd_arch = rd;
      dispatch1_imm = imm;
    end
  endtask

  task automatic check_mem0_request;
    input [1023:0] label;
    input exp_write;
    input [`XLEN-1:0] exp_addr;
    input check_wdata;
    input [`XLEN-1:0] exp_wdata;
    input check_wstrb;
    input [`STRB_W-1:0] exp_wstrb;
    begin
      tb_check1({label, " request visible"}, mem_req_valid, 1'b1);
      tb_check1({label, " request write"}, mem_req_write, exp_write);
      tb_check32({label, " request addr"}, mem_req_addr[31:0],
                 exp_addr[31:0]);
      if (check_wdata) begin
        tb_check32({label, " request wdata"}, mem_req_wdata[31:0],
                   exp_wdata[31:0]);
      end
      if (check_wstrb) begin
        tb_check32({label, " request wstrb"},
                   {{(32-`STRB_W){1'b0}}, mem_req_wstrb},
                   {{(32-`STRB_W){1'b0}}, exp_wstrb});
      end
    end
  endtask

  task automatic wait_mem0_request;
    input [1023:0] label;
    input exp_write;
    input [`XLEN-1:0] exp_addr;
    input check_wdata;
    input [`XLEN-1:0] exp_wdata;
    input check_wstrb;
    input [`STRB_W-1:0] exp_wstrb;
    integer wait_cycles;
    begin
      #1;
      wait_cycles = 0;
      while (!mem_req_valid && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      check_mem0_request(label, exp_write, exp_addr, check_wdata,
                         exp_wdata, check_wstrb, exp_wstrb);
    end
  endtask

  task automatic complete_mem0_response;
    input [1023:0] label;
    input [`XLEN-1:0] rsp_data;
    input exp_commit;
    input exp_rd_en;
    input check_data;
    input [`XLEN-1:0] exp_data;
    integer wait_cycles;
    begin
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = rsp_data;
      mem_rsp_error = 1'b0;
      #1;
      wait_cycles = 0;
      while (!mem_rsp_ready && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " rsp ready"}, mem_rsp_ready, 1'b1);
      tb_check1({label, " commit valid"}, commit0_valid, exp_commit);
      if (exp_commit) begin
        tb_check1({label, " commit rd en"}, commit0_rd_en, exp_rd_en);
        if (check_data) begin
          tb_check32({label, " commit data"}, commit0_data[31:0],
                     exp_data[31:0]);
        end
      end
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
    end
  endtask

  // 【P5 刀 B】IQ dispatch→issue 同拍 bypass 已删除:dispatch 拍只入队(issue_count=2),
  // 次拍从寄存项双发,再次拍 EX+wb 直通 commit——整链较旧契约后移一拍。
  task automatic tick_dispatch_to_commit;
    input [1023:0] label;
    input [`XLEN-1:0] exp0;
    input [`XLEN-1:0] exp1;
    begin
      #1;
      tb_check1({label, " dispatch0 ready"}, dispatch0_ready, 1'b1);
      tb_check1({label, " dispatch1 ready"}, dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32({label, " rob has two entries"}, {27'b0, rob_count}, 32'd2);
      tb_check32({label, " ready uops queued in iq"}, {28'b0, issue_count}, 32'd2);
      tb_check1({label, " no same-cycle execute"}, execute0_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32({label, " queued pair issues"}, {28'b0, issue_count}, 32'd0);
      tb_check1({label, " execute0 captures"}, execute0_valid, 1'b1);
      tb_check1({label, " execute1 captures"}, execute1_valid, 1'b1);
      tb_check1({label, " commit0 valid via wb bypass"}, commit0_valid, 1'b1);
      tb_check1({label, " commit1 valid via wb bypass"}, commit1_valid, 1'b1);
      tb_check32({label, " commit0 data via wb bypass"}, commit0_data, exp0);
      tb_check32({label, " commit1 data via wb bypass"}, commit1_data, exp1);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " rob drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " iq drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"}, {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic wait_commit0_data64;
    input [1023:0] label;
    input [`XLEN-1:0] exp_data;
    input integer max_cycles;
    integer wait_cycles;
    begin
      wait_cycles = 0;
      while (!commit0_valid && (wait_cycles < max_cycles)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " commit0 valid"}, commit0_valid, 1'b1);
      tb_check1({label, " commit0 rd en"}, commit0_rd_en, 1'b1);
      if (commit0_valid) begin
        tb_check64({label, " commit0 data"}, commit0_data, exp_data);
      end
      `TB_TICK(clk);
      #1;
      tb_check32({label, " rob drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " iq drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"}, {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic run_clmul_backend_case;
    input [1023:0] label;
    input [`XLEN-1:0] pc;
    input [2:0] funct3;
    input [4:0] rd;
    input [1:0] op;
    begin
      set_dispatch0(pc, make_bitmanip_op_ctrl(), 5'd22, 5'd23, rd, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd23, 5'd22, funct3, rd);
      #1;
      tb_check1({label, " dispatch ready"}, dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1({label, " does not use ex0 one-cycle path"},
                execute0_valid, 1'b0);
      tb_check1({label, " waits for long-op response"}, commit0_valid, 1'b0);
      tb_check32({label, " rob holds long op"}, {27'b0, rob_count}, 32'd1);
      wait_commit0_data64(label,
                          ref_clmul(op, 64'h1234_5678_9abc_def0,
                                    64'hfedc_ba98_7654_3210),
                          90);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    tb_check32("initial freelist count", {25'b0, free_count}, 32'd32);
    tb_check32("initial rob count", {27'b0, rob_count}, 32'd0);
    tb_check32("initial issue count", {28'b0, issue_count}, 32'd0);

    set_dispatch0(32'h8000_0000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd5, 32'd7);
    set_dispatch1(32'h8000_0004,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd6, 32'd9);
    tick_dispatch_to_commit("dual independent addi", 32'd7, 32'd9);

    set_dispatch0(32'h8000_0010,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd7, 32'd7);
    set_dispatch1(32'h8000_0014,
                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b1, 1'b0, 1'b1),
                  5'd7, 5'd0, 5'd8, 32'd3);
    #1;
    tb_check1("dependent dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("dependent dispatch1 ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // N+1 契约:两条 uop 均先入队;producer 先发,consumer 等 producer 的 wb wakeup
    // (同拍 wakeup→select 直通),依次经 commit0 退休——不再有同拍双发前递/双 commit。
    tb_check32("dependent pair queued", {28'b0, issue_count}, 32'd2);
    `TB_TICK(clk);
    #1;
    tb_check32("consumer waits in iq", {28'b0, issue_count}, 32'd1);
    tb_check1("producer enters execute", execute0_valid, 1'b1);
    tb_check1("producer commits via wb bypass", commit0_valid, 1'b1);
    tb_check32("producer result via wb bypass", commit0_data, 32'd7);
    `TB_TICK(clk);
    #1;
    tb_check32("consumer issues on wb wakeup", {28'b0, issue_count}, 32'd0);
    tb_check1("consumer enters execute", execute0_valid, 1'b1);
    tb_check1("consumer commits via wb bypass", commit0_valid, 1'b1);
    tb_check32("consumer result uses producer value", commit0_data, 32'd10);

    `TB_TICK(clk);
    #1;
    tb_check32("dependent rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("dependent iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("dependent freelist recovers", {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_0800,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd5, 32'd1);
    #1;
    tb_check1("branch bypass producer dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check32("branch producer queued in iq", {28'b0, issue_count}, 32'd1);

    set_dispatch0(32'h8000_0804,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd5, 5'd0, 5'd0, 32'd8);
    #1;
    // domain-A(OOO_DBRANCH_DOMAIN_A=1): dispatch 拍快解析对分支禁用(fast 路不产生
    // mispredict/ROB-walk kill, 会放走 wrong-path); 分支恒经 IQ 由 issue 级 resolve。
    tb_check1("branch dispatch fast resolve disabled (domain-A)",
              dispatch_branch_resolve_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    repeat (4) begin
      `TB_TICK(clk);
    end
    #1;
    tb_check32("branch bypass rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("branch bypass iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("branch bypass freelist recovers", {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_1000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_COPY_B,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd9, 32'h1234_5000);
    set_dispatch1(32'h8000_1004,
                  make_alu_ctrl(`OP1_SEL_PC, `OP2_SEL_FOUR, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd10, 32'd0);
    tick_dispatch_to_commit("operand select", 32'h1234_5000, 32'h8000_1008);

    set_dispatch0(32'h8000_1800,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_COPY_B,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd17, 64'hf0f1_0001_0000_0000);
    #1;
    tb_check1("bitmanip setup dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // 【P5 刀 B】setup uop 需 issue(次拍)+EX/commit(再次拍):先排干再投依赖对,
    // 避免 rob 残留与 x17 busy 未清。
    `TB_TICK(clk);
    #1;
    `TB_TICK(clk);
    #1;
    tb_check32("bitmanip setup drains", {27'b0, rob_count}, 32'd0);

    // Zbb count 类指令走 bitmanip helper 的 byte 分层组合树，direct TB 锁住 64-bit 边界值。
    set_dispatch0(32'h8000_1810, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd18, 64'd0);
    dispatch0_inst = inst_op_imm(7'h30, 5'h00, 5'd17,
                                 `FUNCT3_SLL, 5'd18);
    set_dispatch1(32'h8000_1814, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd19, 64'd0);
    dispatch1_inst = inst_op_imm(7'h30, 5'h01, 5'd17,
                                 `FUNCT3_SLL, 5'd19);
    tick_dispatch_to_commit("bitmanip clz ctz", 32'd0, 32'd32);

    set_dispatch0(32'h8000_1820, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd20, 64'd0);
    dispatch0_inst = inst_op_imm(7'h30, 5'h02, 5'd17,
                                 `FUNCT3_SLL, 5'd20);
    set_dispatch1(32'h8000_1824, make_bitmanip_ctrl(),
                  5'd0, 5'd0, 5'd21, 64'd0);
    dispatch1_inst = inst_op_imm(7'h30, 5'h00, 5'd0,
                                 `FUNCT3_SLL, 5'd21);
    tick_dispatch_to_commit("bitmanip cpop clz-zero", 32'd10, 32'd64);

    set_dispatch0(32'h8000_1840,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                `ALU_OP_COPY_B, 1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd22, 64'h1234_5678_9abc_def0);
    set_dispatch1(32'h8000_1844,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                `ALU_OP_COPY_B, 1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd23, 64'hfedc_ba98_7654_3210);
    tick_dispatch_to_commit("clmul setup operands", 32'h9abc_def0,
                            32'h7654_3210);

    run_clmul_backend_case("backend clmul", 32'h8000_1850,
                           `FUNCT3_SLL, 5'd24, 2'd0);
    run_clmul_backend_case("backend clmulh", 32'h8000_1860,
                           `FUNCT3_SLT, 5'd25, 2'd1);
    run_clmul_backend_case("backend clmulr", 32'h8000_1870,
                           `FUNCT3_SLTU, 5'd26, 2'd2);

    set_dispatch0(32'h8000_2000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd11, 32'd11);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    // 【P5 刀 B】dispatch 次拍 issue、再次拍才进 EX;flush 打在 EX 拍。
    tb_check32("flush setup queued", {28'b0, issue_count}, 32'd1);
    `TB_TICK(clk);
    #1;
    tb_check1("flush setup execute valid", execute0_valid, 1'b1);
    flush = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("flush clears execute0", execute0_valid, 1'b0);
	    tb_check1("flush clears execute1", execute1_valid, 1'b0);
	    tb_check32("flush clears rob", {27'b0, rob_count}, 32'd0);
	    tb_check32("flush clears issue queue", {28'b0, issue_count}, 32'd0);
	    tb_check32("flush restores freelist", {25'b0, free_count}, 32'd32);

    // dual-load 第二端口(mem1)死硅删除:原"两 load 同拍双端口发射"用例已无效,移除。
    // 两 load 串行经主端口 mem0 的覆盖由下方 buffer-seed 用例与 riscv-tests 承担。
	    mem_rsp_valid = 1'b0;
	    set_dispatch0(32'h8000_2600,
	                  make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
	                  5'd0, 5'd0, 5'd15, 32'h8000_0270);  // 【F2】EA 入 pmem: 非 pmem load 现按 MMIO 队头独占, 本场景测 buffer 串行化
	    #1;
	    tb_check1("buffer seed load dispatch ready", dispatch0_ready, 1'b1);
	    // 【P5 刀 B】load 不再 dispatch 拍直通:req 在 issue 拍(次拍)组合出 AGU 才可见。
	    tb_check1("no same-cycle load request", mem_req_valid, 1'b0);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("buffer seed load request visible", mem_req_valid, 1'b1);
	    tb_check1("buffer seed load is read", mem_req_write, 1'b0);
	    tb_check32("buffer seed load addr", mem_req_addr, 32'h8000_0270);

	    set_dispatch0(32'h8000_2604,
	                  make_load_ctrl(`MEM_SIZE_HALF, 1'b1),
	                  5'd0, 5'd0, 5'd16, 32'h8000_0276);
	    #1;
	    tb_check1("buffered lhu dispatch ready", dispatch0_ready, 1'b1);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    // 【LSQ/MIQ 语义】plain load 背靠背在飞(rsp 恒配 MIQ 队头), 旧"单例串行等待"
	    // 断言依赖第一条 load 落 MMIO 区占 mem_pending 的巧合, 地址入 pmem 后按真语义更新。
	    // 【P5 刀 B】第二条 load 的 req 同样在其 issue 拍(dispatch 次拍)可见。
	    tb_check1("plain lhu back-to-back issues", mem_req_valid, 1'b1);
	    tb_check1("plain lhu back-to-back is read", mem_req_write, 1'b0);
	    tb_check32("plain lhu back-to-back addr", mem_req_addr, 32'h8000_0276);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("no third request in flight", mem_req_valid, 1'b0);

	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_1234_5678;
	    mem_rsp_error = 1'b0;
	    #1;
	    tb_check1("buffer seed rsp ready", mem_rsp_ready, 1'b1);
	    tb_check1("buffer seed commit valid", commit0_valid, 1'b1);
	    tb_check32("buffer seed commit data", commit0_data, 32'h1234_5678);
	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b0;
	    #1;

	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_0000_1800;
	    mem_rsp_error = 1'b0;
	    #1;
	    tb_check1("buffered lhu rsp ready", mem_rsp_ready, 1'b1);
	    tb_check1("buffered lhu commit valid", commit0_valid, 1'b1);
	    tb_check32("buffered lhu commit data", commit0_data, 32'h0000_1800);
	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b0;
	    #1;
	    tb_check32("buffered lhu rob drains", {27'b0, rob_count}, 32'd0);
	    tb_check32("buffered lhu iq drains", {28'b0, issue_count}, 32'd0);
	    tb_check32("buffered lhu freelist recovers", {25'b0, free_count}, 32'd32);

		    set_dispatch0(32'h8000_2800,
		                  make_store_ctrl(`MEM_SIZE_WORD),
		                  5'd0, 5'd0, 5'd0, 32'h0000_0200);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("store starts memory request", mem_req_valid, 1'b1);
	    tb_check1("store request is write", mem_req_write, 1'b1);
	    tb_check32("store request addr", mem_req_addr, 32'h0000_0200);

	    `TB_TICK(clk);
	    #1;
	    set_dispatch0(32'h8000_2810,
	                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
	                                1'b0, 1'b0, 1'b1),
	                  5'd0, 5'd0, 5'd13, 32'd21);
	    set_dispatch1(32'h8000_2814,
	                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
	                                1'b0, 1'b0, 1'b1),
	                  5'd0, 5'd0, 5'd14, 32'd22);
	    #1;
	    tb_check1("dual alu dispatch under mem pending lane0 ready", dispatch0_ready, 1'b1);
	    tb_check1("dual alu dispatch under mem pending lane1 ready", dispatch1_ready, 1'b1);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    // 【P5 刀 B】双 ALU 先入队,次拍双发,再次拍进 EX——wb 口占满/rsp 反压后移一拍。
	    tb_check32("dual alu under mem pending queued", {28'b0, issue_count}, 32'd2);
	    `TB_TICK(clk);
	    #1;
	    tb_check32("dual alu under mem pending issues", {28'b0, issue_count}, 32'd0);
	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 32'h0;
	    mem_rsp_error = 1'b0;
	    #1;
	    tb_check1("dual alu under mem pending execute0", execute0_valid, 1'b1);
	    tb_check1("dual alu under mem pending execute1", execute1_valid, 1'b1);
	    tb_check1("full wb ports backpressure mem rsp", mem_rsp_ready, 1'b0);
	    tb_check1("head store cannot commit while rsp backpressured", commit0_valid, 1'b0);

	    `TB_TICK(clk);
	    #1;
	    tb_check1("mem rsp accepted after wb port frees", mem_rsp_ready, 1'b1);
	    tb_check1("store commits after delayed rsp", commit0_valid, 1'b1);
	    tb_check1("first alu commits beside delayed store", commit1_valid, 1'b1);
	    tb_check1("store has no rd write", commit0_rd_en, 1'b0);
	    tb_check32("first alu data beside delayed store", commit1_data, 32'd21);

	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b0;
	    #1;
	    tb_check1("second alu commits after delayed store pair", commit0_valid, 1'b1);
	    tb_check32("second alu data after delayed store pair", commit0_data, 32'd22);

	    `TB_TICK(clk);
	    #1;
	    tb_check32("dual alu mem overlap rob drains", {27'b0, rob_count}, 32'd0);
	    tb_check32("dual alu mem overlap iq drains", {28'b0, issue_count}, 32'd0);
	    tb_check32("dual alu mem overlap freelist recovers", {25'b0, free_count}, 32'd32);

	    mem_rsp_valid = 1'b0;
	    set_dispatch0(32'h8000_3000,
	                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
	                                1'b0, 1'b0, 1'b1),
	                  5'd0, 5'd0, 5'd12, 32'h0000_0055);
	    set_dispatch1(32'h8000_3004,
	                  make_store_ctrl(`MEM_SIZE_WORD),
	                  5'd0, 5'd0, 5'd0, 32'h0000_0100);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    // 【P5 刀 B】ALU+store 先同拍入队(store 有更老 valid 项,整拍被序阻塞);
	    // ALU 次拍发射、再次拍 EX/commit,store 随后独占发射。
	    tb_check32("alu+store pair queued", {28'b0, issue_count}, 32'd2);
	    `TB_TICK(clk);
	    #1;
	    tb_check32("lane1 store waits in iq", {28'b0, issue_count}, 32'd1);
	    tb_check1("lane0 alu writes before delayed lane1 store", execute0_valid, 1'b1);
	    tb_check1("lane0 alu commits before delayed lane1 store", commit0_valid, 1'b1);
	    tb_check32("lane0 alu commit data before store", commit0_data, 32'h0000_0055);
	    wait_mem0_request("lane1 store", 1'b1, 32'h0000_0100,
	                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});

	    `TB_TICK(clk);
	    #1;
	    complete_mem0_response("lane1 store", {`XLEN{1'b0}},
	                           1'b1, 1'b0, 1'b0, {`XLEN{1'b0}});
	    tb_check32("lane1 store rob drains", {27'b0, rob_count}, 32'd0);
	    tb_check32("lane1 store iq drains", {28'b0, issue_count}, 32'd0);
	    tb_check32("lane1 store freelist recovers", {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_4000,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd1, 32'h0000_0300);
    set_dispatch1(32'h8000_4004,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd2, 32'd5);
    tick_dispatch_to_commit("amo setup base/value", 32'h0000_0300, 32'd5);

    mem_rsp_valid = 1'b0;
    set_dispatch0(32'h8000_4010,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                  5'd1, 5'd0, 5'd3, 32'd0);
    dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd1, `FUNCT3_LD, 5'd3);
    #1;
    tb_check1("lr.d dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("lr.d", 1'b0, 32'h0000_0300,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    complete_mem0_response("lr.d", 64'h1111_2222_3333_4444,
                           1'b1, 1'b1, 1'b1,
                           64'h0000_0000_3333_4444);

    set_dispatch0(32'h8000_4020,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                  5'd1, 5'd2, 5'd4, 32'd0);
    dispatch0_inst = inst_amo(5'b00011, 5'd2, 5'd1, `FUNCT3_LD, 5'd4);
    #1;
    tb_check1("sc.d success dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("sc.d success", 1'b1, 32'h0000_0300,
                      1'b1, 32'd5, 1'b1, 8'hff);
    `TB_TICK(clk);
    #1;
    complete_mem0_response("sc.d success", {`XLEN{1'b0}},
                           1'b1, 1'b1, 1'b1, {`XLEN{1'b0}});

    set_dispatch0(32'h8000_4030,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                  5'd1, 5'd2, 5'd4, 32'd0);
    dispatch0_inst = inst_amo(5'b00011, 5'd2, 5'd1, `FUNCT3_LD, 5'd4);
    #1;
    tb_check1("sc.d fail dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("sc.d fail has no memory write", mem_req_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check1("sc.d fail commits", commit0_valid, 1'b1);
    tb_check32("sc.d fail returns one", commit0_data, 32'd1);
    `TB_TICK(clk);
    #1;

    set_dispatch0(32'h8000_4040,
                  make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
                  5'd1, 5'd2, 5'd5, 32'd0);
    dispatch0_inst = inst_amo(5'b00000, 5'd2, 5'd1, `FUNCT3_LD, 5'd5);
    #1;
    tb_check1("amoadd.d dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("amoadd.d read", 1'b0, 32'h0000_0300,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.d read", 64'd7,
                           1'b0, 1'b0, 1'b0, {`XLEN{1'b0}});
    wait_mem0_request("amoadd.d write", 1'b1, 32'h0000_0300,
                      1'b1, 32'd12, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.d write", {`XLEN{1'b0}},
                           1'b1, 1'b1, 1'b1, 64'd7);
    tb_check32("amo sequence rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("amo sequence iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("amo sequence freelist recovers", {25'b0, free_count}, 32'd32);

    set_dispatch0(32'h8000_4050,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd1, 32'h0000_0304);
    set_dispatch1(32'h8000_4054,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd2, 32'd1);
    tick_dispatch_to_commit("amo word x0 setup", 32'h0000_0304, 32'd1);

    mem_rsp_valid = 1'b0;
    set_dispatch0(32'h8000_4060,
                  make_amo_ctrl(`MEM_SIZE_WORD, 1'b0, 1'b0),
                  5'd1, 5'd2, 5'd0, 32'd0);
    dispatch0_inst = inst_amo(5'b00000, 5'd2, 5'd1, `FUNCT3_LW, 5'd0);
    #1;
    tb_check1("amoadd.w x0 dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    wait_mem0_request("amoadd.w x0 read", 1'b0, 32'h0000_0304,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.w x0 read", 64'd7,
                           1'b0, 1'b0, 1'b0, {`XLEN{1'b0}});
    wait_mem0_request("amoadd.w x0 write", 1'b1, 32'h0000_0304,
                      1'b1, 32'd8, 1'b1, 8'h0f);
    `TB_TICK(clk);
    #1;
    complete_mem0_response("amoadd.w x0 write", {`XLEN{1'b0}},
                           1'b1, 1'b0, 1'b1, 64'd7);
    tb_check32("amoadd.w x0 rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("amoadd.w x0 iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("amoadd.w x0 freelist recovers", {25'b0, free_count}, 32'd32);

	    tb_finish("tb_ooo_int_backend");
  end
endmodule
