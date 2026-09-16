`ifdef V11T_CLMUL_PRODUCER_FOCUSED
  // One complete ROB turn followed by the two operand-setup uops makes the
  // next allocation P0={generation=1,index=2}.  The stimulus schedule owns
  // this expected ProducerId; no expected identity is sampled from the DUT.
  localparam [PRODUCER_ID_W-1:0] V11T_PID =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 2);
  localparam [PRODUCER_ID_W-1:0] V11T_WRONG_GEN_PID =
      V11T_PID ^ (1 << ROB_INDEX_W);
  localparam [`XLEN-1:0] V11T_TARGET_PC =
      64'h0000_0000_8001_7c00;
  localparam [`XLEN-1:0] V11T_LHS =
      64'h1234_5678_9abc_def0;
  localparam [`XLEN-1:0] V11T_RHS =
      64'h0fed_cba9_8765_4321;

  task automatic v11t_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11T-CLMUL-PRODUCER-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11t_prime_operands;
    begin
      reset_dut();
      run_v8n_prime_producer_generation();
      set_dispatch0(
          V11T_TARGET_PC - 64'h20,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd1, V11T_LHS);
      set_dispatch1(
          V11T_TARGET_PC - 64'h1c,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd2, V11T_RHS);
      tick_dispatch_to_commit("V11T operand setup", V11T_LHS, V11T_RHS);
      if ((rob_count !== 0) || (issue_count !== 0))
        v11t_oracle_fail("identity-prime-drain");
    end
  endtask

  task automatic v11t_check_holder;
    input [1023:0] stage;
    reg [(1 << PRODUCER_ID_W)-1:0] expected_mask;
    begin
      expected_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_mask[V11T_PID] = 1'b1;
      if ((dut.u_clmul_unit.producer_id_q !== V11T_PID) ||
          (dut.clmul_owner_valid_w !== 1'b1) ||
          (dut.clmul_owner_producer_id_w !== V11T_PID))
        v11t_oracle_fail(stage);
      if (dut.clmul_owner_producer_live_mask_w !== expected_mask)
        v11t_oracle_fail("iterative-hold-live-mask");
      if ((dut.external_producer_live_mask_w[V11T_PID] !== 1'b1) ||
          (dut.producer_live_mask_w[V11T_PID] !== 1'b1))
        v11t_oracle_fail("iterative-hold-global-live");
    end
  endtask

  task automatic v11t_run_terminal;
    input [1023:0] label;
    input [2:0] funct3;
    input [1:0] op;
    integer wait_cycle;
    integer commit_count;
    reg [`XLEN-1:0] expected_result;
    begin
      expected_result = ref_clmul(op, V11T_LHS, V11T_RHS);
      v11t_prime_operands();
      set_dispatch0(
          V11T_TARGET_PC, make_bitmanip_op_ctrl(),
          5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst =
          inst_op(7'h05, 5'd2, 5'd1, funct3, 5'd9);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11T_PID))
        v11t_oracle_fail("dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_valid_w !== 1'b1) ||
          (dut.issue0_is_clmul_w !== 1'b1) ||
          (dut.iq_issue0_producer_id_w !== V11T_PID))
        v11t_oracle_fail("issue-accept");
      `TB_TICK(clk);
      #1;
      if (dut.u_clmul_unit.state_q !== 2'd1)
        v11t_oracle_fail("request-buffer-birth");
      v11t_check_holder("request-buffer-birth");
      $display("[V11T-CLMUL-BIRTH][PASS] kind=%0s pid=%0h state=RUN",
               label, V11T_PID);

      wait_cycle = 0;
      while ((dut.clmul_resp_valid_w !== 1'b1) &&
             (wait_cycle < 70)) begin
        v11t_check_holder("iterative-hold");
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if (dut.clmul_resp_valid_w !== 1'b1)
        v11t_oracle_fail("terminal-timeout");
      if (dut.u_clmul_unit.state_q !== 2'd2)
        v11t_oracle_fail("terminal-state");
      v11t_check_holder("terminal-old-lease");
      $display("[V11T-CLMUL-HOLD][PASS] kind=%0s cycles=%0d pid=%0h",
               label, wait_cycle, V11T_PID);

      // Substitute only the response identity.  The resident holder and the
      // real ROB entry remain unchanged; same-index/other-generation must not
      // gain completion authority or a writeback claim.
      force dut.clmul_resp_producer_id_w = V11T_WRONG_GEN_PID;
      #1;
      if (dut.clmul_completion_rob_open_w !== 1'b0)
        v11t_oracle_fail("wrong-generation-query");
      if ((dut.clmul_completion_authorized_w !== 1'b0) ||
          (dut.clmul_wb0_valid_w !== 1'b0) ||
          (dut.clmul_wb1_valid_w !== 1'b0))
        v11t_oracle_fail("wrong-generation-authorization");
      release dut.clmul_resp_producer_id_w;
      #1;
      $display("[V11T-CLMUL-WRONG-GEN][PASS] expected=%0h rejected=%0h",
               V11T_PID, V11T_WRONG_GEN_PID);

      if ((dut.clmul_resp_producer_id_w !== V11T_PID) ||
          (dut.clmul_resp_rob_idx_w !==
           V11T_PID[ROB_INDEX_W-1:0]) ||
          (dut.clmul_resp_data_w !== expected_result) ||
          (dut.clmul_completion_rob_open_w !== 1'b1) ||
          (dut.clmul_completion_authorized_w !== 1'b1) ||
          (!(dut.clmul_wb0_valid_w || dut.clmul_wb1_valid_w)) ||
          (dut.clmul_resp_ready_w !== 1'b1))
        v11t_oracle_fail("terminal-authorization");
      if (!((dut.clmul_wb0_valid_w &&
             (dut.wb0_producer_id_w === V11T_PID) &&
             (dut.wb0_data_w === expected_result)) ||
            (dut.clmul_wb1_valid_w &&
             (dut.wb1_producer_id_w === V11T_PID) &&
             (dut.wb1_data_w === expected_result))))
        v11t_oracle_fail("terminal-wb-identity");
      `TB_TICK(clk);
      #1;
      if ((dut.clmul_owner_valid_w !== 1'b0) ||
          (dut.u_clmul_unit.state_q !== 2'd0) ||
          (dut.u_clmul_unit.producer_id_q !==
           {PRODUCER_ID_W{1'b0}}) ||
          (dut.clmul_owner_producer_live_mask_w !==
           {(1 << PRODUCER_ID_W){1'b0}}))
        v11t_oracle_fail("terminal-release");

      commit_count = 0;
      wait_cycle = 0;
      while ((commit_count == 0) && (wait_cycle < 8)) begin
        if (commit0_valid) begin
          if ((commit0_producer_id !== V11T_PID) ||
              (commit0_data !== expected_result))
            v11t_oracle_fail("ordered-retirement");
          commit_count = commit_count + 1;
        end
        if (commit1_valid) begin
          if ((dut.u_dispatch_backend.rob_commit1_producer_id_w !==
               V11T_PID) || (commit1_data !== expected_result))
            v11t_oracle_fail("ordered-retirement");
          commit_count = commit_count + 1;
        end
        if (commit_count == 0) begin
          `TB_TICK(clk);
          #1;
          wait_cycle = wait_cycle + 1;
        end
      end
      if (commit_count !== 1)
        v11t_oracle_fail("ordered-retirement");
      `TB_TICK(clk);
      #1;
      if (commit0_valid || commit1_valid || (rob_count !== 0))
        v11t_oracle_fail("ordered-retirement-exactly-once");
      $display("[V11T-CLMUL-TERMINAL][PASS] kind=%0s pid=%0h result=%0h birth=1 hold=1 death=1",
               label, V11T_PID, expected_result);
    end
  endtask

  task automatic v11t_run_flush_death;
    begin
      v11t_prime_operands();
      set_dispatch0(
          V11T_TARGET_PC, make_bitmanip_op_ctrl(),
          5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst =
          inst_op(7'h05, 5'd2, 5'd1, `FUNCT3_SLL, 5'd9);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11T_PID))
        v11t_oracle_fail("flush-seed-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_valid_w !== 1'b1) ||
          (dut.iq_issue0_producer_id_w !== V11T_PID))
        v11t_oracle_fail("flush-seed-issue");
      `TB_TICK(clk);
      #1;
      if (dut.u_clmul_unit.state_q !== 2'd1)
        v11t_oracle_fail("flush-seed-birth");
      v11t_check_holder("flush-seed-birth");
      `TB_TICK(clk);
      #1;
      v11t_check_holder("flush-seed-hold");

      flush = 1'b1;
      #1;
      if ((dut.clmul_owner_valid_w !== 1'b1) ||
          (dut.clmul_resp_valid_w !== 1'b0) ||
          (dut.clmul_req_ready_w !== 1'b0))
        v11t_oracle_fail("flush-death-edge");
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      if ((dut.clmul_owner_valid_w !== 1'b0) ||
          (dut.u_clmul_unit.state_q !== 2'd0) ||
          (dut.u_clmul_unit.producer_id_q !==
           {PRODUCER_ID_W{1'b0}}) ||
          (dut.clmul_owner_producer_live_mask_w !==
           {(1 << PRODUCER_ID_W){1'b0}}) ||
          (dut.producer_live_mask_w[V11T_PID] !== 1'b0) ||
          dut.wb0_valid_w || dut.wb1_valid_w)
        v11t_oracle_fail("flush-death");
      $display("[V11T-CLMUL-FLUSH][PASS] pid=%0h death=1 next_cycle_empty=1",
               V11T_PID);
    end
  endtask

  task automatic run_v11t_clmul_producer_semantic;
    begin
      v11t_run_terminal("CLMUL", `FUNCT3_SLL, 2'd0);
      v11t_run_terminal("CLMULH", `FUNCT3_SLT, 2'd1);
      v11t_run_flush_death();
      $display("[V11T-CLMUL-PRODUCER-MATRIX][PASS] product_instance=1 stimulus_pid=1 generation=1 index=2 capture=2 hold=2 wrong_generation=2 terminal=2 flush=1");
    end
  endtask
`endif
