  // Current-design V14G overlay.  The stable runner injects this block into a
  // temporary copy of tb_ooo_int_backend.sv so existing source-bound semantic
  // evidence keeps the immutable base testbench hash.
  task automatic v14g_global_owner_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V14G-GLOBAL-OWNER-ORACLE][FAIL] stage=%0s gen_w=%0d @%0t",
               stage, PRODUCER_GEN_W, $time);
      $fatal(1);
    end
  endtask

  // The holder schedule is real: slot0 is advanced to generation=1, a LOAD
  // moves from IntIQ into the reservation+tracker owner, flush terminates the
  // reservation through collector lane6, and tracker dequeue0 performs the
  // exact death.  Only candidate/parallel observation wires are overridden;
  // no overridden READY=1 candidate crosses a rising edge.
  task run_v14g_global_producer_owner_fence;
    reg [PRODUCER_ID_W-1:0] seed_pid;
    reg [PRODUCER_ID_W-1:0] memory_pid;
    reg [PRODUCER_ID_W-1:0] wrong_generation_pid;
    reg [PRODUCER_ID_W-1:0] pending_pid;
    reg [4:0] owner_token;
    reg [1:0] owner_kind;
    reg [1:0] owner_epoch;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      // Consume generation zero for slot0, then use ordinary flush.  OooRob
      // preserves slot_generation_q across flush, so the real LOAD below owns
      // generation one in both GEN_W=1 and product-width configurations.
      set_dispatch0(64'h0000_0000_8001_8000,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd3, 64'd1);
      #1;
      seed_pid = dispatch0_producer_id;
      if ((dispatch0_ready !== 1'b1) ||
          (|seed_pid[PRODUCER_ID_W-1:ROB_INDEX_W]))
        v14g_global_owner_oracle_fail("generation-prime-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      if ((rob_count !== 0) || (issue_count !== 0) ||
          dut.producer_live_mask_w[seed_pid])
        v14g_global_owner_oracle_fail("generation-prime-flush");

      set_dispatch0(64'h0000_0000_8001_8010,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd4, 64'h0000_0000_0000_1800);
      #1;
      memory_pid = dispatch0_producer_id;
      wrong_generation_pid = memory_pid;
      wrong_generation_pid[ROB_INDEX_W] = ~memory_pid[ROB_INDEX_W];
      if ((dispatch0_ready !== 1'b1) ||
          !(|memory_pid[PRODUCER_ID_W-1:ROB_INDEX_W]) ||
          (wrong_generation_pid[ROB_INDEX_W-1:0] !==
           memory_pid[ROB_INDEX_W-1:0]))
        v14g_global_owner_oracle_fail("memory-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (!dut.mem_issue_res_capture_candidate_w ||
          !dut.mem_issue_res_capture_w)
        v14g_global_owner_oracle_fail("memory-capture-candidate");
      if (!dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid])
        v14g_global_owner_oracle_fail("memory-capture-int-iq-holder");

      // On the capture edge the tracker is still edge-old empty.  The IntIQ
      // resident Q must therefore be sufficient to reject this exact P.
      set_dispatch0(64'h0000_0000_8001_8020,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd2);
      force dut.u_dispatch_backend.rob_dispatch0_producer_id_w = memory_pid;
      #1;
      if (!dut.mem_issue_res_capture_w ||
          !dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid] ||
          !dut.producer_live_mask_w[memory_pid] ||
          (dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("birth-edge-old");
      $display("[V14G-BIRTH-EDGE-OLD][PASS] pid=%0h source=int_iq",
               memory_pid);
      `TB_TICK(clk);
      #1;
      owner_token = dut.mem_issue_res_owner_token_q;
      owner_kind = dut.mem_issue_res_owner_kind_q;
      owner_epoch = dut.mem_issue_res_mmu_epoch_q;
      if (dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid] ||
          !dut.mem_issue_res_valid_q ||
          (dut.mem_issue_res_producer_id_q !== memory_pid) ||
          !dut.mem_owner_live_mask_w[owner_token] ||
          !dut.mem_owner_producer_live_mask_w[memory_pid] ||
          !dut.producer_live_mask_w[memory_pid] ||
          (dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("birth-owner-only");
      $display("[V14G-OWNER-BIRTH][PASS] pid=%0h token=%0d kind=%0d epoch=%0d",
               memory_pid, owner_token, owner_kind, owner_epoch);

      // Isolate the simultaneous real LQ/reservation/tracker Q contributors.
      // Every force is combinational, crosses no edge, and is checked after
      // release before the source is consumed again.
      force dut.mem_owner_producer_live_mask_w =
          {(1 << PRODUCER_ID_W){1'b0}};
      force dut.mem_res_producer_live_mask_w =
          {(1 << PRODUCER_ID_W){1'b0}};
      #1;
      if (!dut.lq_producer_live_mask_w[memory_pid] ||
          !dut.producer_live_mask_w[memory_pid] ||
          (dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("load-queue-union");
      release dut.mem_res_producer_live_mask_w;
      #1;
      if (!dut.mem_res_producer_live_mask_w[memory_pid])
        v14g_global_owner_oracle_fail("reservation-force-release");
      force dut.lq_producer_live_mask_w =
          {(1 << PRODUCER_ID_W){1'b0}};
      #1;
      if (!dut.mem_res_producer_live_mask_w[memory_pid] ||
          !dut.producer_live_mask_w[memory_pid] ||
          (dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("reservation-union");
      release dut.lq_producer_live_mask_w;
      release dut.mem_owner_producer_live_mask_w;
      #1;
      if (!dut.lq_producer_live_mask_w[memory_pid] ||
          !dut.mem_owner_producer_live_mask_w[memory_pid])
        v14g_global_owner_oracle_fail("union-force-release");
      $display("[V14G-UNION-ISOLATION][PASS] lq=1 reservation=1 tracker=1 pid=%0h",
               memory_pid);

      // Same ROB index in another generation is not live.
      force dut.u_dispatch_backend.rob_dispatch0_producer_id_w =
          wrong_generation_pid;
      #1;
      if (dut.producer_live_mask_w[wrong_generation_pid] ||
          (dispatch0_ready !== 1'b1) || !dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("generation-separation");

      // Mandatory lane1 is one atomic pair: a live lane1 pair candidate closes
      // lane0 before either allocation fires.
      set_dispatch1(64'h0000_0000_8001_8024,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'd3);
      force dut.u_dispatch_backend.rob_dispatch1_pair_producer_id_w =
          memory_pid;
      force dut.u_dispatch_backend.rob_dispatch1_producer_id_w = memory_pid;
      #1;
      if (dut.u_dispatch_backend.dispatch1_pair_ready_w ||
          (dispatch0_ready !== 1'b0) || (dispatch1_ready !== 1'b0) ||
          dut.dispatch0_fire_w || dut.dispatch1_fire_w)
        v14g_global_owner_oracle_fail("lane1-mandatory");

      // Optional lane1 may be dropped, while the unrelated lane0 remains
      // admissible.  The production parent ties optional low, so this one
      // combinational probe overrides only the child input and never clocks it.
      force dut.u_dispatch_backend.dispatch1_optional_i = 1'b1;
      #1;
      if (!dut.u_dispatch_backend.dispatch1_pair_ready_w ||
          (dispatch0_ready !== 1'b1) || !dut.dispatch0_fire_w ||
          (dispatch1_ready !== 1'b0) || dut.dispatch1_fire_w)
        v14g_global_owner_oracle_fail("lane1-optional");
      $display("[V14G-DISPATCH-LANE-MATRIX][PASS] lane0_exact=blocked wrong_generation=open mandatory_pair=blocked optional_lane1=dropped");

      release dut.u_dispatch_backend.dispatch1_optional_i;
      release dut.u_dispatch_backend.rob_dispatch1_pair_producer_id_w;
      release dut.u_dispatch_backend.rob_dispatch1_producer_id_w;
      clear_dispatch();
      #1;

      // Flush ends reservation and LQ/ROB/IQ holders, but the terminal enters
      // collector lane6 and the tracker remains sole live-P truth until the
      // registered dequeue0/free edge.
      flush = 1'b1;
      #1;
      if (!dut.mem_issue_res_global_cancel_w ||
          !dut.mem_terminal_ingress_valid_w[6] ||
          !dut.mem_terminal_ingress_accept_w[6] ||
          (dut.mem_terminal_ingress_kind_w[(6*2) +: 2] !== owner_kind) ||
          (dut.mem_terminal_ingress_token_w[(6*5) +: 5] !== owner_token) ||
          (dut.mem_terminal_ingress_epoch_w[(6*2) +: 2] !== owner_epoch) ||
          !dut.mem_terminal_ingress6_mask_w[owner_token] ||
          !dut.producer_live_mask_w[memory_pid])
        v14g_global_owner_oracle_fail("terminal-lane6-ingress");
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      if (dut.mem_issue_res_valid_q ||
          dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid] ||
          dut.lq_producer_live_mask_w[memory_pid] ||
          !dut.mem_terminal_pending_mask_w[owner_token] ||
          !dut.mem_owner_producer_live_mask_w[memory_pid] ||
          !dut.producer_live_mask_w[memory_pid])
        v14g_global_owner_oracle_fail("collector-pending-owner-only");
      $display("[V14G-OWNER-ONLY-LIVE][PASS] pid=%0h token=%0d source=tracker collector_pending=1",
               memory_pid, owner_token);

      set_dispatch0(64'h0000_0000_8001_8030,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'd4);
      force dut.u_dispatch_backend.rob_dispatch0_producer_id_w = memory_pid;
      #1;
      if ((dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w ||
          dut.mem_terminal_deq0_valid_w)
        v14g_global_owner_oracle_fail("collector-output-refill-old");
      `TB_TICK(clk);
      #1;
      if (!dut.mem_terminal_deq0_valid_w ||
          !dut.mem_terminal_deq0_ready_w ||
          (dut.mem_terminal_deq0_kind_w !== owner_kind) ||
          (dut.mem_terminal_deq0_token_w !== owner_token) ||
          (dut.mem_terminal_deq0_epoch_w !== owner_epoch) ||
          !dut.mem_owner_producer_live_mask_w[memory_pid] ||
          !dut.producer_live_mask_w[memory_pid] ||
          (dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("death-edge-old");
      $display("[V14G-DEATH-EDGE-OLD][PASS] pid=%0h token=%0d dequeue=0",
               memory_pid, owner_token);
      `TB_TICK(clk);
      #1;
      if (dut.mem_owner_live_mask_w[owner_token] ||
          dut.mem_owner_producer_live_mask_w[memory_pid] ||
          dut.producer_live_mask_w[memory_pid] ||
          dut.mem_terminal_pending_mask_w[owner_token] ||
          (dispatch0_ready !== 1'b1) || !dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("death-release-next-cycle");

      clear_dispatch();
      release dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      #1;
      // Pending-system is a registered full-P lease supplied by ControlPlane.
      // With no other holder live it must independently close and reopen lane0.
      set_dispatch0(64'h0000_0000_8001_8040,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'd5);
      #1;
      pending_pid = dispatch0_producer_id;
      pending_system_producer_id = pending_pid;
      pending_system_producer_valid = 1'b1;
      #1;
      if (!dut.pending_system_producer_live_mask_w[pending_pid] ||
          !dut.producer_live_mask_w[pending_pid] ||
          (dispatch0_ready !== 1'b0) || dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("pending-system-union");
      pending_system_producer_valid = 1'b0;
      #1;
      if (dut.producer_live_mask_w[pending_pid] ||
          (dispatch0_ready !== 1'b1) || !dut.dispatch0_fire_w)
        v14g_global_owner_oracle_fail("pending-system-release");
      clear_dispatch();
      $display("[V14G-PENDING-SYSTEM-UNION][PASS] pid=%0h birth=blocked death=open",
               pending_pid);
      $display("[V14G-GLOBAL-PRODUCER-OWNER][PASS] gen_w=%0d birth=1 owner_only=1 lane_matrix=1 death=1",
               PRODUCER_GEN_W);
      reset_dut();
    end
  endtask
