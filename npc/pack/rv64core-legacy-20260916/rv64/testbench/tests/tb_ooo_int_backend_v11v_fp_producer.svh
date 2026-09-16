`ifdef V11V_FP_PRODUCER_FOCUSED
  // One complete ROB turn makes the next allocation P0={generation=1,index=0}.
  // The testbench owns this expected identity; no expected ProducerId is
  // sampled from an RTL holder or completion output.
  localparam [PRODUCER_ID_W-1:0] V11V_PID =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W));
  localparam [PRODUCER_ID_W-1:0] V11V_WRONG_GEN_PID =
      V11V_PID ^ (1 << ROB_INDEX_W);
  localparam integer V11V_KIND_ARITH = 0;
  localparam integer V11V_KIND_EXEC1 = 1;
  localparam integer V11V_KIND_LONG = 2;
  localparam integer V11V_PHASE_DONE = 0;
  localparam integer V11V_PHASE_DONE_LIVE = 1;
  localparam integer V11V_PHASE_WRONG_GEN = 2;
  localparam integer V11V_PHASE_TERMINAL_AUTH = 3;
  localparam integer V11V_PHASE_TERMINAL_RELEASE = 4;
  localparam integer V11V_PHASE_RETIRE = 5;

  task automatic v11v_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11V-FP-PRODUCER-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11v_kind_fail;
    input integer kind;
    input integer phase;
    begin
      case (kind)
        V11V_KIND_ARITH: begin
          case (phase)
            V11V_PHASE_DONE:
              v11v_oracle_fail("arith-done-fifo");
            V11V_PHASE_DONE_LIVE:
              v11v_oracle_fail("arith-done-fifo-live");
            V11V_PHASE_WRONG_GEN:
              v11v_oracle_fail("arith-wrong-generation");
            V11V_PHASE_TERMINAL_AUTH:
              v11v_oracle_fail("arith-terminal-authorization");
            V11V_PHASE_TERMINAL_RELEASE:
              v11v_oracle_fail("arith-terminal-release");
            default:
              v11v_oracle_fail("arith-ordered-retirement");
          endcase
        end
        V11V_KIND_EXEC1: begin
          case (phase)
            V11V_PHASE_DONE:
              v11v_oracle_fail("exec1-done-fifo");
            V11V_PHASE_DONE_LIVE:
              v11v_oracle_fail("exec1-done-fifo-live");
            V11V_PHASE_WRONG_GEN:
              v11v_oracle_fail("exec1-wrong-generation");
            V11V_PHASE_TERMINAL_AUTH:
              v11v_oracle_fail("exec1-terminal-authorization");
            V11V_PHASE_TERMINAL_RELEASE:
              v11v_oracle_fail("exec1-terminal-release");
            default:
              v11v_oracle_fail("exec1-ordered-retirement");
          endcase
        end
        default: begin
          case (phase)
            V11V_PHASE_DONE:
              v11v_oracle_fail("long-done-fifo");
            V11V_PHASE_DONE_LIVE:
              v11v_oracle_fail("long-done-fifo-live");
            V11V_PHASE_WRONG_GEN:
              v11v_oracle_fail("long-wrong-generation");
            V11V_PHASE_TERMINAL_AUTH:
              v11v_oracle_fail("long-terminal-authorization");
            V11V_PHASE_TERMINAL_RELEASE:
              v11v_oracle_fail("long-terminal-release");
            default:
              v11v_oracle_fail("long-ordered-retirement");
          endcase
        end
      endcase
    end
  endtask

  task automatic v11v_prime_identity;
    begin
      reset_dut();
      run_v8n_prime_producer_generation();
      if ((rob_count !== 0) || (issue_count !== 0) ||
          (dut.u_fp_backend.fp_iq_count_w !== 0) ||
          (dut.u_fp_backend.done_fifo_count_q !== 0))
        v11v_oracle_fail("identity-prime-drain");
    end
  endtask

  task automatic v11v_check_iq_and_issue;
    input integer kind;
    begin
      if ((dut.u_fp_backend.iq_issue_valid_w !== 1'b1) ||
          (dut.u_fp_backend.iq_issue_producer_id_w !== V11V_PID)) begin
        case (kind)
          V11V_KIND_ARITH: v11v_oracle_fail("arith-iq-birth");
          V11V_KIND_EXEC1: v11v_oracle_fail("exec1-iq-birth");
          default: v11v_oracle_fail("long-iq-birth");
        endcase
      end
      if ((dut.u_fp_backend.fp_iq_producer_live_mask_w[V11V_PID] !== 1'b1) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1) ||
          (dut.producer_live_mask_w[V11V_PID] !== 1'b1)) begin
        case (kind)
          V11V_KIND_ARITH: v11v_oracle_fail("arith-iq-birth-live");
          V11V_KIND_EXEC1: v11v_oracle_fail("exec1-iq-birth-live");
          default: v11v_oracle_fail("long-iq-birth-live");
        endcase
      end
      $display("[V11V-FP-IQ][PASS] kind=%0d pid=%0h", kind, V11V_PID);

      `TB_TICK(clk);
      #1;
      if ((dut.u_fp_backend.fp_issue_stage_valid_w !== 1'b1) ||
          (dut.u_fp_backend.issue_producer_id_w !== V11V_PID) ||
          (dut.u_fp_backend.issue_rob_idx_w !==
           V11V_PID[ROB_INDEX_W-1:0])) begin
        case (kind)
          V11V_KIND_ARITH: v11v_oracle_fail("arith-issue-stage");
          V11V_KIND_EXEC1: v11v_oracle_fail("exec1-issue-stage");
          default: v11v_oracle_fail("long-issue-stage");
        endcase
      end
      if ((dut.u_fp_backend.issue_stage_producer_live_mask_w[V11V_PID] !==
           1'b1) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1) ||
          (dut.producer_live_mask_w[V11V_PID] !== 1'b1)) begin
        case (kind)
          V11V_KIND_ARITH: v11v_oracle_fail("arith-issue-stage-live");
          V11V_KIND_EXEC1: v11v_oracle_fail("exec1-issue-stage-live");
          default: v11v_oracle_fail("long-issue-stage-live");
        endcase
      end
      $display("[V11V-FP-ISSUE][PASS] kind=%0d pid=%0h", kind, V11V_PID);
    end
  endtask

  task automatic v11v_check_done_and_retire;
    input integer kind;
    integer hold_cycle;
    integer wait_cycle;
    integer retire_count;
    begin
      if ((dut.u_fp_backend.done_fifo_count_q !== 4'd1) ||
          (dut.u_fp_backend.df_valid_q[dut.u_fp_backend.df_head_q] !== 1'b1) ||
          (dut.u_fp_backend.df_producer_id_q[
              dut.u_fp_backend.df_head_q] !== V11V_PID) ||
          (dut.fpwb_producer_id_w !== V11V_PID))
        v11v_kind_fail(kind, V11V_PHASE_DONE);
      if ((dut.fp_completion_pending_mask_w[V11V_PID] !== 1'b1) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1) ||
          (dut.producer_live_mask_w[V11V_PID] !== 1'b1))
        v11v_kind_fail(kind, V11V_PHASE_DONE_LIVE);
      for (hold_cycle = 0; hold_cycle < 2; hold_cycle = hold_cycle + 1) begin
        `TB_TICK(clk);
        #1;
        if ((dut.u_fp_backend.done_fifo_count_q !== 4'd1) ||
            (dut.fpwb_producer_id_w !== V11V_PID) ||
            (dut.fp_completion_pending_mask_w[V11V_PID] !== 1'b1))
          v11v_kind_fail(kind, V11V_PHASE_DONE_LIVE);
      end
      $display("[V11V-FP-DONE][PASS] kind=%0d pid=%0h hold=2",
               kind, V11V_PID);

      force dut.fpwb_producer_id_w = V11V_WRONG_GEN_PID;
      #1;
      if ((dut.fp_formal_completion_rob_open_w !== 1'b0) ||
          (dut.fpwb_completion_authorized_w !== 1'b0) ||
          (dut.fpwb_wb0_valid_w !== 1'b0) ||
          (dut.fpwb_wb1_valid_w !== 1'b0))
        v11v_kind_fail(kind, V11V_PHASE_WRONG_GEN);
      release dut.fpwb_producer_id_w;
      #1;
      $display("[V11V-FP-WRONG-GEN][PASS] kind=%0d expected=%0h rejected=%0h",
               kind, V11V_PID, V11V_WRONG_GEN_PID);

      release dut.fpwb_to_wb0_w;
      release dut.fpwb_to_wb1_w;
      #1;
      if ((dut.fp_formal_completion_rob_open_w !== 1'b1) ||
          (dut.fpwb_completion_authorized_w !== 1'b1) ||
          (dut.fpwb_ready_w !== 1'b1) ||
          (!(dut.fpwb_wb0_valid_w || dut.fpwb_wb1_valid_w)))
        v11v_kind_fail(kind, V11V_PHASE_TERMINAL_AUTH);
      if ((dut.fpwb_wb0_valid_w &&
           (dut.wb0_producer_id_w !== V11V_PID)) ||
          (dut.fpwb_wb1_valid_w &&
           (dut.wb1_producer_id_w !== V11V_PID)))
        v11v_kind_fail(kind, V11V_PHASE_TERMINAL_AUTH);

      `TB_TICK(clk);
      #1;
      if ((dut.u_fp_backend.done_fifo_count_q !== 4'd0) ||
          (dut.fp_completion_pending_mask_w[V11V_PID] !== 1'b0) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b0))
        v11v_kind_fail(kind, V11V_PHASE_TERMINAL_RELEASE);

      retire_count = 0;
      wait_cycle = 0;
      while ((retire_count == 0) && (wait_cycle < 12)) begin
        if (commit0_valid) begin
          if (commit0_producer_id !== V11V_PID)
            v11v_kind_fail(kind, V11V_PHASE_RETIRE);
          retire_count = retire_count + 1;
        end
        if (commit1_valid) begin
          if (dut.u_dispatch_backend.rob_commit1_producer_id_w !== V11V_PID)
            v11v_kind_fail(kind, V11V_PHASE_RETIRE);
          retire_count = retire_count + 1;
        end
        if (retire_count == 0) begin
          `TB_TICK(clk);
          #1;
          wait_cycle = wait_cycle + 1;
        end
      end
      if (retire_count !== 1)
        v11v_kind_fail(kind, V11V_PHASE_RETIRE);
      `TB_TICK(clk);
      #1;
      if (commit0_valid || commit1_valid || (rob_count !== 0))
        v11v_kind_fail(kind, V11V_PHASE_RETIRE);
      $display("[V11V-FP-TERMINAL][PASS] kind=%0d pid=%0h birth=1 hold=1 death=1 retire=1",
               kind, V11V_PID);
    end
  endtask

  task automatic v11v_run_arith;
    integer stage_i;
    begin
      v11v_prime_identity();
      force dut.fpwb_to_wb0_w = 1'b0;
      force dut.fpwb_to_wb1_w = 1'b0;
      set_fp_binary0(64'h0000_0000_8001_8000, 7'b0000001,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11V_PID))
        v11v_oracle_fail("arith-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      v11v_check_iq_and_issue(V11V_KIND_ARITH);
      `TB_TICK(clk);
      #1;
      for (stage_i = 0; stage_i < 5; stage_i = stage_i + 1) begin
        if ((dut.u_fp_backend.arith_owner_valid_w[stage_i] !== 1'b1) ||
            (dut.u_fp_backend.arith_owner_producer_id_w[
                stage_i*PRODUCER_ID_W +: PRODUCER_ID_W] !== V11V_PID)) begin
          if (stage_i == 0)
            v11v_oracle_fail("arith-stage1");
          else
            v11v_oracle_fail("arith-pipeline-hold");
        end
        if ((dut.u_fp_backend.arith_producer_live_mask_r[V11V_PID] !== 1'b1) ||
            (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1)) begin
          if (stage_i == 0)
            v11v_oracle_fail("arith-stage1-live");
          else
            v11v_oracle_fail("arith-pipeline-live");
        end
        if (stage_i < 4) begin
          `TB_TICK(clk);
          #1;
        end
      end
      if ((dut.u_fp_backend.arith_out_valid_w !== 1'b1) ||
          (dut.u_fp_backend.result_query_producer_id_o !== V11V_PID) ||
          (dut.u_fp_backend.df_push_w !== 1'b1))
        v11v_oracle_fail("arith-result-transfer");
      $display("[V11V-FP-ARITH][PASS] pid=%0h stages=5", V11V_PID);
      `TB_TICK(clk);
      #1;
      v11v_check_done_and_retire(V11V_KIND_ARITH);
    end
  endtask

  task automatic v11v_run_exec1;
    begin
      v11v_prime_identity();
      force dut.fpwb_to_wb0_w = 1'b0;
      force dut.fpwb_to_wb1_w = 1'b0;
      set_fp_binary0(64'h0000_0000_8001_8020, 7'b0010001,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11V_PID))
        v11v_oracle_fail("exec1-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      v11v_check_iq_and_issue(V11V_KIND_EXEC1);
      `TB_TICK(clk);
      #1;
      if ((dut.u_fp_backend.exec1_valid_q !== 1'b1) ||
          (dut.u_fp_backend.exec1_producer_id_q !== V11V_PID) ||
          (dut.u_fp_backend.exec1_rob_q !==
           V11V_PID[ROB_INDEX_W-1:0]))
        v11v_oracle_fail("exec1-stage");
      if ((dut.u_fp_backend.exec1_producer_live_mask_w[V11V_PID] !== 1'b1) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1))
        v11v_oracle_fail("exec1-stage-live");
      if ((dut.u_fp_backend.result_query_producer_id_o !== V11V_PID) ||
          (dut.u_fp_backend.df_push_w !== 1'b1))
        v11v_oracle_fail("exec1-result-transfer");
      $display("[V11V-FP-EXEC1][PASS] pid=%0h stage=1", V11V_PID);
      `TB_TICK(clk);
      #1;
      v11v_check_done_and_retire(V11V_KIND_EXEC1);
    end
  endtask

  task automatic v11v_run_long;
    integer hold_cycle;
    begin
      v11v_prime_identity();
      force dut.fpwb_to_wb0_w = 1'b0;
      force dut.fpwb_to_wb1_w = 1'b0;
      set_fp_binary0(64'h0000_0000_8001_8040, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11V_PID))
        v11v_oracle_fail("long-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      v11v_check_iq_and_issue(V11V_KIND_LONG);
      `TB_TICK(clk);
      #1;
      if ((dut.u_fp_backend.long_meta_valid_q !== 1'b1) ||
          (dut.u_fp_backend.long_producer_id_q !== V11V_PID))
        v11v_oracle_fail("long-birth");
      if ((dut.u_fp_backend.long_producer_live_mask_w[V11V_PID] !== 1'b1) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1))
        v11v_oracle_fail("long-birth-live");
      hold_cycle = 0;
      while ((dut.u_fp_backend.long_done_hold_q !== 1'b1) &&
             (hold_cycle < 80)) begin
        if ((dut.u_fp_backend.long_meta_valid_q !== 1'b1) ||
            (dut.u_fp_backend.long_producer_id_q !== V11V_PID) ||
            (dut.u_fp_backend.long_producer_live_mask_w[V11V_PID] !== 1'b1))
          v11v_oracle_fail("long-iterative-hold");
        `TB_TICK(clk);
        #1;
        hold_cycle = hold_cycle + 1;
      end
      if ((dut.u_fp_backend.long_done_hold_q !== 1'b1) ||
          (dut.u_fp_backend.long_producer_id_q !== V11V_PID) ||
          (dut.u_fp_backend.result_query_producer_id_o !== V11V_PID) ||
          (dut.u_fp_backend.df_push_w !== 1'b1))
        v11v_oracle_fail("long-result-transfer");
      $display("[V11V-FP-LONG][PASS] pid=%0h hold_cycles=%0d",
               V11V_PID, hold_cycle);
      `TB_TICK(clk);
      #1;
      v11v_check_done_and_retire(V11V_KIND_LONG);
    end
  endtask

  task automatic v11v_run_flush_death;
    integer wait_cycle;
    begin
      v11v_prime_identity();
      force dut.fpwb_to_wb0_w = 1'b0;
      force dut.fpwb_to_wb1_w = 1'b0;
      set_fp_binary0(64'h0000_0000_8001_8060, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycle = 0;
      while ((dut.u_fp_backend.long_meta_valid_q !== 1'b1) &&
             (wait_cycle < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((dut.u_fp_backend.long_meta_valid_q !== 1'b1) ||
          (dut.u_fp_backend.long_producer_id_q !== V11V_PID) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b1))
        v11v_oracle_fail("flush-seed-hold");
      flush = 1'b1;
      #1;
      if (dut.u_fp_backend.long_meta_valid_q !== 1'b1)
        v11v_oracle_fail("flush-death-edge");
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      if ((dut.u_fp_backend.long_meta_valid_q !== 1'b0) ||
          (dut.u_fp_backend.fp_issue_stage_valid_w !== 1'b0) ||
          (dut.u_fp_backend.done_fifo_count_q !== 4'd0) ||
          (dut.fp_producer_live_mask_w[V11V_PID] !== 1'b0) ||
          dut.fpwb_wb0_valid_w || dut.fpwb_wb1_valid_w)
        v11v_oracle_fail("flush-death");
      release dut.fpwb_to_wb0_w;
      release dut.fpwb_to_wb1_w;
      $display("[V11V-FP-FLUSH][PASS] pid=%0h death=1", V11V_PID);
    end
  endtask

  task automatic run_v11v_fp_producer_semantic;
    begin
      v11v_run_arith();
      v11v_run_exec1();
      v11v_run_long();
      v11v_run_flush_death();
      $display("[V11V-FP-PRODUCER-MATRIX][PASS] product_instance=1 stimulus_pid=1 generation=1 index=0 iq=3 issue=3 arith=1 exec1=1 long=1 done=3 wrong_generation=3 terminal=3 flush=1");
    end
  endtask
`endif
