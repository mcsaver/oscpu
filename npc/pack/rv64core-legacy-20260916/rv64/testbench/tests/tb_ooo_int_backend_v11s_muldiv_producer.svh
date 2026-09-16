`ifdef V11S_MULDIV_PRODUCER_FOCUSED
  // One complete ROB turn followed by the two operand-setup uops makes the
  // next allocation P0={generation=1,index=2}.  This expected ProducerId is
  // owned by the stimulus schedule; it is never sampled from MulDiv state.
  localparam [PRODUCER_ID_W-1:0] V11S_PID =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 2);
  localparam [PRODUCER_ID_W-1:0] V11S_WRONG_GEN_PID =
      V11S_PID ^ (1 << ROB_INDEX_W);
  localparam [`XLEN-1:0] V11S_TARGET_PC =
      64'h0000_0000_8001_7800;
  localparam [`XLEN-1:0] V11S_MUL_LHS =
      64'h1234_5678_9abc_def0;
  localparam [`XLEN-1:0] V11S_MUL_RHS =
      64'h0fed_cba9_8765_4321;
  localparam [`XLEN-1:0] V11S_MUL_RESULT =
      64'h2236_d88f_e561_8cf0;
  localparam [`XLEN-1:0] V11S_DIV_LHS =
      64'hffff_ffff_ffff_ffff;
  localparam [`XLEN-1:0] V11S_DIV_RHS = 64'd3;
  localparam [`XLEN-1:0] V11S_DIV_RESULT =
      64'h5555_5555_5555_5555;

  task automatic v11s_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11S-MULDIV-PRODUCER-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11s_prime_operands;
    input [`XLEN-1:0] lhs;
    input [`XLEN-1:0] rhs;
    begin
      reset_dut();
      run_v8n_prime_producer_generation();
      set_dispatch0(
          V11S_TARGET_PC - 64'h20,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd1, lhs);
      set_dispatch1(
          V11S_TARGET_PC - 64'h1c,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd2, rhs);
      tick_dispatch_to_commit("V11S operand setup", lhs, rhs);
      if ((rob_count !== 0) || (issue_count !== 0))
        v11s_oracle_fail("identity-prime-drain");
    end
  endtask

  task automatic v11s_check_holder;
    input [1023:0] stage;
    reg [(1 << PRODUCER_ID_W)-1:0] expected_mask;
    begin
      expected_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_mask[V11S_PID] = 1'b1;
      if ((dut.u_muldiv_unit.producer_id_q !== V11S_PID) ||
          (dut.muldiv_owner_valid_w !== 1'b1) ||
          (dut.muldiv_owner_producer_id_w !== V11S_PID))
        v11s_oracle_fail(stage);
      if (dut.muldiv_owner_producer_live_mask_w !== expected_mask)
        v11s_oracle_fail("iterative-hold-live-mask");
      if ((dut.external_producer_live_mask_w[V11S_PID] !== 1'b1) ||
          (dut.producer_live_mask_w[V11S_PID] !== 1'b1))
        v11s_oracle_fail("iterative-hold-global-live");
    end
  endtask

  task automatic v11s_run_terminal;
    input [1023:0] label;
    input [2:0] funct3;
    input [`XLEN-1:0] lhs;
    input [`XLEN-1:0] rhs;
    input [`XLEN-1:0] expected_result;
    input is_div;
    integer wait_cycle;
    integer commit_count;
    begin
      v11s_prime_operands(lhs, rhs);
      set_dispatch0(
          V11S_TARGET_PC, make_muldiv_ctrl(),
          5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst =
          inst_op(`FUNCT7_MULDIV, 5'd2, 5'd1, funct3, 5'd9);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11S_PID))
        v11s_oracle_fail("dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_valid_w !== 1'b1) ||
          (dut.issue0_is_muldiv_w !== 1'b1) ||
          (dut.iq_issue0_producer_id_w !== V11S_PID))
        v11s_oracle_fail("issue-accept");
      `TB_TICK(clk);
      #1;
      if (dut.u_muldiv_unit.state_q !== 3'd1)
        v11s_oracle_fail("request-buffer-birth");
      v11s_check_holder("request-buffer-birth");
      $display("[V11S-MULDIV-BIRTH][PASS] kind=%0s pid=%0h state=REQ_BUF",
               label, V11S_PID);

      `TB_TICK(clk);
      #1;
      if (dut.u_muldiv_unit.state_q !== (is_div ? 3'd3 : 3'd2))
        v11s_oracle_fail("iterative-entry");
      wait_cycle = 0;
      while ((dut.muldiv_resp_valid_w !== 1'b1) &&
             (wait_cycle < 40)) begin
        v11s_check_holder("iterative-hold");
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if (dut.muldiv_resp_valid_w !== 1'b1)
        v11s_oracle_fail("terminal-timeout");
      v11s_check_holder("terminal-old-lease");
      $display("[V11S-MULDIV-HOLD][PASS] kind=%0s cycles=%0d pid=%0h",
               label, wait_cycle, V11S_PID);

      // Keep the real ROB entry and holder untouched while substituting only
      // the same-index/other-generation response identity.  Exact-open must
      // reject it; raw transport may still advertise ready.
      force dut.muldiv_resp_producer_id_w = V11S_WRONG_GEN_PID;
      #1;
      if (dut.muldiv_completion_rob_open_w !== 1'b0)
        v11s_oracle_fail("wrong-generation-query");
      if ((dut.muldiv_completion_authorized_w !== 1'b0) ||
          (dut.muldiv_actual_claim_w !== 1'b0))
        v11s_oracle_fail("wrong-generation-authorization");
      release dut.muldiv_resp_producer_id_w;
      #1;
      $display("[V11S-MULDIV-WRONG-GEN][PASS] expected=%0h rejected=%0h",
               V11S_PID, V11S_WRONG_GEN_PID);

      if ((dut.muldiv_resp_producer_id_w !== V11S_PID) ||
          (dut.muldiv_resp_rob_idx_w !==
           V11S_PID[ROB_INDEX_W-1:0]) ||
          (dut.muldiv_resp_data_w !== expected_result) ||
          (dut.muldiv_completion_rob_open_w !== 1'b1) ||
          (dut.muldiv_completion_authorized_w !== 1'b1) ||
          (dut.muldiv_actual_claim_w !== 1'b1) ||
          (dut.muldiv_resp_ready_w !== 1'b1))
        v11s_oracle_fail("terminal-authorization");
      if (!((dut.muldiv_wb0_valid_w &&
             (dut.wb0_producer_id_w === V11S_PID) &&
             (dut.wb0_data_w === expected_result)) ||
            (dut.muldiv_wb1_valid_w &&
             (dut.wb1_producer_id_w === V11S_PID) &&
             (dut.wb1_data_w === expected_result))))
        v11s_oracle_fail("terminal-wb-identity");
      `TB_TICK(clk);
      #1;
      if ((dut.muldiv_owner_valid_w !== 1'b0) ||
          (dut.u_muldiv_unit.state_q !== 3'd0) ||
          (dut.u_muldiv_unit.producer_id_q !==
           {PRODUCER_ID_W{1'b0}}) ||
          (dut.muldiv_owner_producer_live_mask_w !==
           {(1 << PRODUCER_ID_W){1'b0}}))
        v11s_oracle_fail("terminal-release");

      commit_count = 0;
      wait_cycle = 0;
      while ((commit_count == 0) && (wait_cycle < 8)) begin
        if (commit0_valid) begin
          if ((commit0_producer_id !== V11S_PID) ||
              (commit0_data !== expected_result))
            v11s_oracle_fail("ordered-retirement");
          commit_count = commit_count + 1;
        end
        if (commit1_valid) begin
          if ((dut.u_dispatch_backend.rob_commit1_producer_id_w !==
               V11S_PID) || (commit1_data !== expected_result))
            v11s_oracle_fail("ordered-retirement");
          commit_count = commit_count + 1;
        end
        if (commit_count == 0) begin
          `TB_TICK(clk);
          #1;
          wait_cycle = wait_cycle + 1;
        end
      end
      if (commit_count !== 1)
        v11s_oracle_fail("ordered-retirement");
      `TB_TICK(clk);
      #1;
      if (commit0_valid || commit1_valid || (rob_count !== 0))
        v11s_oracle_fail("ordered-retirement-exactly-once");
      $display("[V11S-MULDIV-TERMINAL][PASS] kind=%0s pid=%0h result=%0h birth=1 hold=1 death=1",
               label, V11S_PID, expected_result);
    end
  endtask

  task automatic v11s_run_flush_death;
    begin
      v11s_prime_operands(V11S_MUL_LHS, V11S_MUL_RHS);
      set_dispatch0(
          V11S_TARGET_PC, make_muldiv_ctrl(),
          5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst =
          inst_op(`FUNCT7_MULDIV, 5'd2, 5'd1, 3'b000, 5'd9);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11S_PID))
        v11s_oracle_fail("flush-seed-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_valid_w !== 1'b1) ||
          (dut.iq_issue0_producer_id_w !== V11S_PID))
        v11s_oracle_fail("flush-seed-issue");
      `TB_TICK(clk);
      #1;
      if (dut.u_muldiv_unit.state_q !== 3'd1)
        v11s_oracle_fail("flush-seed-birth");
      v11s_check_holder("flush-seed-birth");
      `TB_TICK(clk);
      #1;
      v11s_check_holder("flush-seed-hold");

      flush = 1'b1;
      #1;
      if ((dut.muldiv_owner_valid_w !== 1'b1) ||
          (dut.muldiv_resp_valid_w !== 1'b0) ||
          (dut.muldiv_req_ready_w !== 1'b0))
        v11s_oracle_fail("flush-death-edge");
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      if ((dut.muldiv_owner_valid_w !== 1'b0) ||
          (dut.u_muldiv_unit.state_q !== 3'd0) ||
          (dut.u_muldiv_unit.producer_id_q !==
           {PRODUCER_ID_W{1'b0}}) ||
          (dut.muldiv_owner_producer_live_mask_w !==
           {(1 << PRODUCER_ID_W){1'b0}}) ||
          (dut.producer_live_mask_w[V11S_PID] !== 1'b0) ||
          dut.wb0_valid_w || dut.wb1_valid_w)
        v11s_oracle_fail("flush-death");
      $display("[V11S-MULDIV-FLUSH][PASS] pid=%0h death=1 next_cycle_empty=1",
               V11S_PID);
    end
  endtask

  task automatic run_v11s_muldiv_producer_semantic;
    begin
      v11s_run_terminal(
          "MUL", 3'b000, V11S_MUL_LHS, V11S_MUL_RHS,
          V11S_MUL_RESULT, 1'b0);
      v11s_run_terminal(
          "DIVU", 3'b101, V11S_DIV_LHS, V11S_DIV_RHS,
          V11S_DIV_RESULT, 1'b1);
      v11s_run_flush_death();
      // Existing V8N stress is retained as a second, differently structured
      // product-path observation: eight younger ALUs issue/complete while
      // the exact MulDiv ProducerId remains resident.
      run_v8n_muldiv_eight_younger(
          "v11s MUL pressure", 3'b000,
          V11S_MUL_LHS, V11S_MUL_RHS, V11S_MUL_RESULT,
          64'h0000_0000_8001_7880, 64'h0000_0000_8001_78a0, 1'b0);
      run_v8n_muldiv_eight_younger(
          "v11s DIVU pressure", 3'b101,
          V11S_DIV_LHS, V11S_DIV_RHS, V11S_DIV_RESULT,
          64'h0000_0000_8001_78c0, 64'h0000_0000_8001_78e0, 1'b1);
      $display("[V11S-MULDIV-PRODUCER-MATRIX][PASS] product_instance=1 stimulus_pid=1 generation=1 index=2 capture=2 hold=2 wrong_generation=2 terminal=2 flush=1 younger_dual_issue=2");
    end
  endtask
`endif
