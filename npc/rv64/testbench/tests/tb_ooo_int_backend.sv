`include "define.v"

module tb_ooo_int_backend;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;
  localparam ROB_INDEX_W = 4;
  localparam ROB_COUNT_W = 5;
  localparam FREE_COUNT_W = 7;
  localparam ISSUE_COUNT_W = 4;
  localparam PRODUCER_GEN_W = `OOO_PRODUCER_GEN_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + PRODUCER_GEN_W;
  localparam V11I_LQ_ENTRY_N = (1 << ROB_INDEX_W);
  localparam FP_ISSUE_PACKET_W =
      PRODUCER_ID_W + `INST_W + (5 * PHY_REG_ADDR_W) + 3;
  localparam integer V8P_KIND_ALU = 0;
  localparam integer V8P_KIND_BRANCH = 1;
  localparam integer V8P_KIND_JAL = 2;
  localparam integer V8P_KIND_JALR = 3;
  localparam integer V8P_KIND_LOAD = 4;
  localparam integer V8P_KIND_STORE = 5;
  localparam integer V8P_EXCLUDED_AMO = 0;
  localparam integer V8P_EXCLUDED_LR = 1;
  localparam integer V8P_EXCLUDED_SC = 2;
  localparam integer V8P_EXCLUDED_FP_LOAD = 3;
  localparam integer V8P_EXCLUDED_FP_STORE = 4;
`ifdef V11R_INT_LANE1_PACKET_FOCUSED
  // Eighteen exact MulDiv retirements make the next dual allocation
  // P0={generation=1,index=2}, P1={generation=1,index=3}.  Both identities
  // come from the stimulus schedule, never from EX1 or memory holder state.
  localparam [PRODUCER_ID_W-1:0] V11R_PID0 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 2);
  localparam [PRODUCER_ID_W-1:0] V11R_PID1 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 3);
  localparam [PRODUCER_ID_W-1:0] V11R_PID1_WRONG_GEN =
      V11R_PID1 ^ (1 << ROB_INDEX_W);
  localparam [`XLEN-1:0] V11R_ALU0_PC =
      64'h0000_0000_8001_7000;
  localparam [`XLEN-1:0] V11R_ALU1_PC =
      64'h0000_0000_8001_7004;
  localparam [`XLEN-1:0] V11R_ALU0_RESULT =
      64'h0f0e_0d0c_0b0a_0908;
  localparam [`XLEN-1:0] V11R_ALU1_RESULT =
      64'h8877_6655_4433_2211;
  localparam [`XLEN-1:0] V11R_MEM0_PC =
      64'h0000_0000_8001_7080;
  localparam [`XLEN-1:0] V11R_MEM1_PC =
      64'h0000_0000_8001_7084;
  localparam [`XLEN-1:0] V11R_MEM0_ADDR =
      64'h0000_0000_0000_1a00;
  localparam [`XLEN-1:0] V11R_MEM1_MISALIGNED =
      64'h0000_0000_0000_1ffe;
  localparam integer V11R_EX_RESULT_LSB =
      `XLEN + `TRAP_CAUSE_W + 1;
  localparam integer V11R_EX_RESULT_MSB =
      V11R_EX_RESULT_LSB + `XLEN - 1;
  localparam integer V11R_EX_PDEST_LSB =
      V11R_EX_RESULT_MSB + 1;
  localparam integer V11R_EX_PDEST_MSB =
      V11R_EX_PDEST_LSB + PHY_REG_ADDR_W - 1;
  localparam integer V11R_EX_ROB_LSB =
      V11R_EX_PDEST_MSB + 1;
  localparam integer V11R_EX_ROB_MSB =
      V11R_EX_ROB_LSB + ROB_INDEX_W - 1;
  localparam integer V11R_EX_GEN_LSB =
      V11R_EX_ROB_MSB + 2;
  localparam integer V11R_EX_GEN_MSB =
      V11R_EX_GEN_LSB + PRODUCER_GEN_W - 1;

  task automatic v11r_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11R-INT-LANE1-PACKET-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11r_prime_identity;
    integer prime_i;
    integer wait_cycle;
    begin
      // The independent MulDiv response path keeps EX1 packet variants from
      // perturbing the allocation schedule before their declared oracle.
      commit_ready = 1'b1;
      for (prime_i = 0; prime_i < 18; prime_i = prime_i + 1) begin
        set_dispatch0(
            64'h0000_0000_8001_6f00 + (prime_i * 4),
            make_muldiv_ctrl(), 5'd0, 5'd0, 5'd0, 64'd0);
        dispatch0_inst =
            inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0, 3'b101, 5'd0);
        #1;
        if (dispatch0_ready !== 1'b1)
          v11r_oracle_fail("identity-prime-dispatch");
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycle = 0;
        while ((commit0_valid !== 1'b1) &&
               (wait_cycle < 24)) begin
          `TB_TICK(clk);
          #1;
          wait_cycle = wait_cycle + 1;
        end
        if ((commit0_valid !== 1'b1) ||
            (commit0_data !== {`XLEN{1'b1}}))
          v11r_oracle_fail("identity-prime-commit");
        `TB_TICK(clk);
        #1;
        if (commit0_valid !== 1'b0)
          v11r_oracle_fail("identity-prime-exactly-once");
      end
      if ((rob_count !== 0) || (issue_count !== 0))
        v11r_oracle_fail("identity-prime-drain");
    end
  endtask

  task automatic v11r_stage_alu_packet;
    reg [PHY_REG_ADDR_W-1:0] expected_pdest0;
    reg [PHY_REG_ADDR_W-1:0] expected_pdest1;
    reg [PRODUCER_ID_W-1:0] raw_packet_pid;
    begin
      reset_dut();
      v11r_prime_identity();
      commit_ready = 1'b0;
      set_dispatch0(
          V11R_ALU0_PC,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd5, V11R_ALU0_RESULT);
      set_dispatch1(
          V11R_ALU1_PC,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd6, V11R_ALU1_RESULT);
      #1;
      expected_pdest0 = dut.dispatch0_pdest_w;
      expected_pdest1 = dut.dispatch1_new_pdest_probe_w;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11R_PID0) ||
          (dut.dispatch1_producer_id_w !== V11R_PID1))
        v11r_oracle_fail("alu-dual-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_fire_w !== 1'b1) ||
          (dut.issue1_exec_fire_w !== 1'b1) ||
          (dut.ex0_up_valid_w !== 1'b1) ||
          (dut.ex1_up_valid_w !== 1'b1) ||
          (dut.ex1_up_from_mem_w !== 1'b0) ||
          (dut.ex1_up_producer_id_w !== V11R_PID1) ||
          (dut.ex1_up_result_w !== V11R_ALU1_RESULT) ||
          (dut.issue0_pdest_w !== expected_pdest0) ||
          (dut.issue1_pdest_w !== expected_pdest1))
        v11r_oracle_fail("alu-up-packet");
      `TB_TICK(clk);
      #1;
      if ((dut.ex0_valid_q !== 1'b1) ||
          (dut.ex1_valid_q !== 1'b1))
        v11r_oracle_fail("alu-stage-birth");
      raw_packet_pid = {
          dut.ex1_down_payload_w[
              V11R_EX_GEN_MSB:V11R_EX_GEN_LSB],
          dut.ex1_down_payload_w[
              V11R_EX_ROB_MSB:V11R_EX_ROB_LSB]
      };
      if (raw_packet_pid !== V11R_PID1)
        v11r_oracle_fail("alu-down-packet-pid");
      if (dut.ex1_producer_id_q !== V11R_PID1)
        v11r_oracle_fail("alu-down-alias-pid");
      if ((dut.ex1_down_payload_w[
               V11R_EX_RESULT_MSB:V11R_EX_RESULT_LSB] !==
           V11R_ALU1_RESULT) ||
          (dut.ex1_result_q !== V11R_ALU1_RESULT) ||
          (dut.ex1_down_payload_w[
               V11R_EX_PDEST_MSB:V11R_EX_PDEST_LSB] !==
           expected_pdest1) ||
          (dut.ex1_pdest_q !== expected_pdest1))
        v11r_oracle_fail("alu-down-payload");
      if ((dut.ex1_exception_q !== 1'b0) ||
          (dut.ex1_cause_q !== {`TRAP_CAUSE_W{1'b0}}) ||
          (dut.ex1_tval_q !== {`XLEN{1'b0}}))
        v11r_oracle_fail("alu-down-control");
      if ((dut.ex1_pre_auth_valid_w !== 1'b1) ||
          (dut.ex1_producer_open_w !== 1'b1) ||
          (dut.ex1_same_edge_claimed_w !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b1) ||
          (dut.wb1_producer_id_w !== V11R_PID1) ||
          (dut.wb1_pdest_w !== expected_pdest1) ||
          (dut.wb1_data_w !== V11R_ALU1_RESULT))
        v11r_oracle_fail("alu-completion-authority");

      // Hold EX0 semantically open while changing only its generation to
      // match EX1's ROB index.  Full-P equality must not claim EX1.
      force dut.ex0_producer_id_q = V11R_PID1_WRONG_GEN;
      force dut.ex0_producer_open_w = 1'b1;
      #1;
      if ((dut.ex0_wb_valid_w !== 1'b1) ||
          (dut.ex1_same_edge_claimed_w !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b1))
        v11r_oracle_fail("same-index-wrong-generation-fence");
      release dut.ex0_producer_id_q;
      release dut.ex0_producer_open_w;
      #1;

      // Keep the registered payload live and change only the EX1 generation.
      // The exact ROB query must close and suppress all completion authority.
      force dut.ex1_producer_id_q = V11R_PID1_WRONG_GEN;
      #1;
      if ((dut.ex1_producer_open_w !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b0))
        v11r_oracle_fail("alu-wrong-generation-authorization");
      release dut.ex1_producer_id_q;
      #1;
      `TB_TICK(clk);
      #1;
      if ((dut.ex1_valid_q !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b0))
        v11r_oracle_fail("alu-one-cycle-death");
      $display("[V11R-EX1-ALU-PACKET][PASS] pid=%0h result=%0h birth=1 death=1",
               V11R_PID1, V11R_ALU1_RESULT);
      $display("[V11R-EX1-AUTH-EDGES][PASS] exact_open=1 wrong_generation=1 same_index_other_generation=1");
    end
  endtask

  task automatic v11r_stage_local_memory_packet;
    reg [PHY_REG_ADDR_W-1:0] expected_pdest0;
    reg [PHY_REG_ADDR_W-1:0] expected_pdest1;
    reg [PRODUCER_ID_W-1:0] raw_packet_pid;
    begin
      reset_dut();
      v11r_prime_identity();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(
          V11R_MEM0_PC, make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
          5'd0, 5'd0, 5'd14, V11R_MEM0_ADDR);
      set_dispatch1(
          V11R_MEM1_PC, make_load_ctrl(`MEM_SIZE_DWORD, 1'b0),
          5'd0, 5'd0, 5'd15, V11R_MEM1_MISALIGNED);
      #1;
      expected_pdest0 = dut.dispatch0_pdest_w;
      expected_pdest1 = dut.dispatch1_new_pdest_probe_w;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11R_PID0) ||
          (dut.dispatch1_producer_id_w !== V11R_PID1))
        v11r_oracle_fail("local-dual-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.iq_memory_pair_w !== 1'b1) ||
          (dut.mem_issue_pair_capture_w !== 1'b1) ||
          (dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_issue1_res_capture_w !== 1'b1))
        v11r_oracle_fail("local-reservation-capture");
      `TB_TICK(clk);
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue1_res_valid_q !== 1'b1) ||
          (dut.mem_issue_res_producer_id_q !== V11R_PID0) ||
          (dut.mem_issue1_res_producer_id_q !== V11R_PID1) ||
          (dut.mem_issue_res_pdest_q !== expected_pdest0) ||
          (dut.mem_issue1_res_pdest_q !== expected_pdest1))
        v11r_oracle_fail("local-reservation-holder");

      mem_translate_active = 1'b1;
      mem1_translate_active = 1'b1;
      #1;
      if ((dut.mem_issue1_res_local_complete_w !== 1'b1) ||
          (dut.mem_issue1_res_consume_fire_w !== 1'b1) ||
          (dut.ex1_up_valid_w !== 1'b1) ||
          (dut.ex1_up_from_mem_w !== 1'b1) ||
          (mem1_req_valid !== 1'b0) ||
          (dut.ex1_up_producer_id_w !== V11R_PID1) ||
          (dut.ex1_up_result_w !== {`XLEN{1'b0}}) ||
          (dut.mem_issue1_res_pdest_q !== expected_pdest1))
        begin
          $display("[V11R-LOCAL-UP-DIAG] local=%b consume=%b ex1_valid=%b from_mem=%b req=%b pid=%h expected_pid=%h result=%h pdest=%h expected_pdest=%h issue1_mem=%b exception=%b addr=%h global_ready=%b order_ready=%b lq_open=%b sc_premature=%b mispredict=%b",
                   dut.mem_issue1_res_local_complete_w,
                   dut.mem_issue1_res_consume_fire_w,
                   dut.ex1_up_valid_w,
                   dut.ex1_up_from_mem_w,
                   mem1_req_valid,
                   dut.ex1_up_producer_id_w,
                   V11R_PID1,
                   dut.ex1_up_result_w,
                   dut.mem_issue1_res_pdest_q,
                   expected_pdest1,
                   dut.issue1_is_mem_w,
                   dut.issue1_mem_exception_w,
                   dut.mem_issue1_res_eff_addr_w,
                   dut.issue0_global_ready_w,
                   dut.issue1_mem_order_ready_w,
                   dut.lq_issue1_open_w,
                   dut.issue1_sc_premature_w,
                   dut.branch_resolve_mispredict_w);
          v11r_oracle_fail("local-up-packet");
        end
      if ((dut.ex1_up_exception_w !== 1'b1) ||
          (dut.ex1_up_cause_w !== `EXC_LOAD_ADDR_MISALIGN))
        v11r_oracle_fail("local-up-exception");
      if (dut.ex1_up_tval_w !== V11R_MEM1_MISALIGNED)
        v11r_oracle_fail("local-up-tval");
      `TB_TICK(clk);
      mem_translate_active = 1'b0;
      mem1_translate_active = 1'b0;
      #1;
      if ((dut.ex1_valid_q !== 1'b1) ||
          (dut.mem_issue1_res_valid_q !== 1'b0))
        v11r_oracle_fail("local-stage-birth");
      raw_packet_pid = {
          dut.ex1_down_payload_w[
              V11R_EX_GEN_MSB:V11R_EX_GEN_LSB],
          dut.ex1_down_payload_w[
              V11R_EX_ROB_MSB:V11R_EX_ROB_LSB]
      };
      if (raw_packet_pid !== V11R_PID1)
        v11r_oracle_fail("local-down-packet-pid");
      if (dut.ex1_producer_id_q !== V11R_PID1)
        v11r_oracle_fail("local-down-alias-pid");
      if ((dut.ex1_pdest_q !== expected_pdest1) ||
          (dut.ex1_result_q !== {`XLEN{1'b0}}) ||
          (dut.ex1_exception_q !== 1'b1) ||
          (dut.ex1_cause_q !== `EXC_LOAD_ADDR_MISALIGN) ||
          (dut.ex1_tval_q !== V11R_MEM1_MISALIGNED))
        v11r_oracle_fail("local-down-payload");
      if ((dut.ex1_pre_auth_valid_w !== 1'b1) ||
          (dut.ex1_producer_open_w !== 1'b1) ||
          (dut.ex1_wb_valid_w !== 1'b1) ||
          (dut.wb1_producer_id_w !== V11R_PID1) ||
          (dut.wb1_pdest_w !== expected_pdest1) ||
          (dut.wb1_exception_w !== 1'b1) ||
          (dut.wb1_cause_w !== `EXC_LOAD_ADDR_MISALIGN) ||
          (dut.wb1_tval_w !== V11R_MEM1_MISALIGNED))
        v11r_oracle_fail("local-completion-authority");
      `TB_TICK(clk);
      #1;
      if ((dut.ex1_valid_q !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b0))
        v11r_oracle_fail("local-one-cycle-death");
      $display("[V11R-EX1-LOCAL-PACKET][PASS] pid=%0h exception=load_misaligned birth=1 death=1",
               V11R_PID1);
      reset_dut();
    end
  endtask

  task automatic v11r_run_flush_edge;
    begin
      reset_dut();
      v11r_prime_identity();
      commit_ready = 1'b0;
      set_dispatch0(
          V11R_ALU0_PC,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd5, V11R_ALU0_RESULT);
      set_dispatch1(
          V11R_ALU1_PC,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd6, V11R_ALU1_RESULT);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1))
        v11r_oracle_fail("flush-dual-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.ex0_up_valid_w !== 1'b1) ||
          (dut.ex1_up_valid_w !== 1'b1))
        v11r_oracle_fail("flush-up-packet");
      `TB_TICK(clk);
      #1;
      if (dut.ex1_valid_q !== 1'b1)
        v11r_oracle_fail("flush-stage-birth");
      force dut.ex1_producer_open_w = 1'b1;
      flush = 1'b1;
      #1;
      if ((dut.ex1_pre_auth_valid_w !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b0))
        v11r_oracle_fail("ex1-flush-cut");
      `TB_TICK(clk);
      flush = 1'b0;
      release dut.ex1_producer_open_w;
      #1;
      if ((dut.ex1_valid_q !== 1'b0) ||
          (dut.ex1_wb_valid_w !== 1'b0))
        v11r_oracle_fail("flush-next-cycle-empty");
      $display("[V11R-EX1-DEATH-EDGES][PASS] flush_mask=1 next_cycle_empty=1");
    end
  endtask

  task automatic run_v11r_int_lane1_packet_semantic;
    begin
      v11r_stage_alu_packet();
      v11r_stage_local_memory_packet();
      v11r_run_flush_edge();
      $display("[V11R-INT-LANE1-PACKET-MATRIX][PASS] ex1_packet=1 ex1_alias=1 alu_source=1 local_memory_source=1 generation=1 index=3 wrong_generation=1 flush=1");
      reset_dut();
    end
  endtask
`endif
`ifdef V11Q_INT_LANE0_PACKET_FOCUSED
  // Eighteen exact MulDiv retirements make the next lane0 allocation
  // P={generation=1,index=2}.  This oracle identity is derived from the
  // stimulus schedule, never from either registered packet holder.
  localparam [PRODUCER_ID_W-1:0] V11Q_PID =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 2);
  localparam [PRODUCER_ID_W-1:0] V11Q_WRONG_GEN_PID =
      V11Q_PID ^ (1 << ROB_INDEX_W);
  localparam [`XLEN-1:0] V11Q_ALU_PC =
      64'h0000_0000_8001_6000;
  localparam [`XLEN-1:0] V11Q_ALU_RESULT =
      64'h1357_9bdf_2468_ace0;
  localparam [`XLEN-1:0] V11Q_BRANCH_PC =
      64'h0000_0000_8001_6080;
  localparam [`XLEN-1:0] V11Q_BRANCH_NEXT_PC =
      V11Q_BRANCH_PC + 64'd8;
  localparam [`BPU_BHT_INDEX_W-1:0] V11Q_BRANCH_BHT =
      10'h2b6;
  localparam integer V11Q_EX_RESULT_LSB =
      `XLEN + `TRAP_CAUSE_W + 1;
  localparam integer V11Q_EX_RESULT_MSB =
      V11Q_EX_RESULT_LSB + `XLEN - 1;
  localparam integer V11Q_EX_PDEST_LSB =
      V11Q_EX_RESULT_MSB + 1;
  localparam integer V11Q_EX_PDEST_MSB =
      V11Q_EX_PDEST_LSB + PHY_REG_ADDR_W - 1;
  localparam integer V11Q_EX_ROB_LSB =
      V11Q_EX_PDEST_MSB + 1;
  localparam integer V11Q_EX_ROB_MSB =
      V11Q_EX_ROB_LSB + ROB_INDEX_W - 1;
  localparam integer V11Q_EX_GEN_LSB =
      V11Q_EX_ROB_MSB + 2;
  localparam integer V11Q_EX_GEN_MSB =
      V11Q_EX_GEN_LSB + PRODUCER_GEN_W - 1;

  task automatic v11q_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11Q-INT-LANE0-PACKET-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11q_prime_identity;
    integer prime_i;
    integer wait_cycle;
    begin
      // Prime through the independent MulDiv response path.  EX0 packet
      // mutations therefore cannot corrupt the allocation schedule before
      // reaching their declared focused observation.
      commit_ready = 1'b1;
      for (prime_i = 0; prime_i < 18; prime_i = prime_i + 1) begin
        set_dispatch0(
            64'h0000_0000_8001_5f00 + (prime_i * 4),
            make_muldiv_ctrl(), 5'd0, 5'd0, 5'd0, 64'd0);
        dispatch0_inst =
            inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0, 3'b101, 5'd0);
        #1;
        if (dispatch0_ready !== 1'b1)
          v11q_oracle_fail("identity-prime-dispatch");
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycle = 0;
        while ((commit0_valid !== 1'b1) &&
               (wait_cycle < 24)) begin
          `TB_TICK(clk);
          #1;
          wait_cycle = wait_cycle + 1;
        end
        if ((commit0_valid !== 1'b1) ||
            (commit0_data !== {`XLEN{1'b1}}))
          v11q_oracle_fail("identity-prime-commit");
        `TB_TICK(clk);
        #1;
        if (commit0_valid !== 1'b0)
          v11q_oracle_fail("identity-prime-exactly-once");
      end
      if ((rob_count !== 0) || (issue_count !== 0))
        v11q_oracle_fail("identity-prime-drain");
    end
  endtask

  task automatic v11q_check_branch_silent;
    input [1023:0] stage;
    begin
      if ((branch_resolve_valid !== 1'b0) ||
          (branch_resolve_pc !== {`XLEN{1'b0}}) ||
          (branch_resolve_next_pc !== {`XLEN{1'b0}}) ||
          (branch_resolve_misaligned !== 1'b0) ||
          (branch_resolve_rob_idx !== {ROB_INDEX_W{1'b0}}) ||
          (branch_resolve_mispredict !== 1'b0) ||
          (branch_resolve_is_branch !== 1'b0) ||
          (branch_resolve_taken !== 1'b0) ||
          (branch_resolve_pred_taken !== 1'b0) ||
          (branch_resolve_bht_idx !==
           {`BPU_BHT_INDEX_W{1'b0}}))
        v11q_oracle_fail(stage);
    end
  endtask

  task automatic v11q_stage_alu_packet;
    reg [PHY_REG_ADDR_W-1:0] expected_pdest;
    reg [PRODUCER_ID_W-1:0] raw_packet_pid;
    begin
      reset_dut();
      v11q_prime_identity();
      commit_ready = 1'b0;
      set_dispatch0(
          V11Q_ALU_PC,
          make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                        `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
          5'd0, 5'd0, 5'd5, V11Q_ALU_RESULT);
      #1;
      expected_pdest = dut.dispatch0_pdest_w;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11Q_PID))
        v11q_oracle_fail("alu-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_fire_w !== 1'b1) ||
          (dut.ex0_up_valid_w !== 1'b1) ||
          (dut.ex0_up_producer_id_w !== V11Q_PID) ||
          (dut.ex0_up_result_w !== V11Q_ALU_RESULT) ||
          (dut.issue0_pdest_w !== expected_pdest))
        v11q_oracle_fail("alu-up-packet");
      `TB_TICK(clk);
      #1;
      if (dut.ex0_valid_q !== 1'b1)
        v11q_oracle_fail("alu-stage-birth");
      raw_packet_pid = {
          dut.ex0_down_payload_w[
              V11Q_EX_GEN_MSB:V11Q_EX_GEN_LSB],
          dut.ex0_down_payload_w[
              V11Q_EX_ROB_MSB:V11Q_EX_ROB_LSB]
      };
      if (raw_packet_pid !== V11Q_PID)
        v11q_oracle_fail("alu-down-packet-pid");
      if (dut.ex0_producer_id_q !== V11Q_PID)
        v11q_oracle_fail("alu-down-alias-pid");
      if ((dut.ex0_down_payload_w[
               V11Q_EX_RESULT_MSB:V11Q_EX_RESULT_LSB] !==
           V11Q_ALU_RESULT) ||
          (dut.ex0_result_q !== V11Q_ALU_RESULT) ||
          (dut.ex0_down_payload_w[
               V11Q_EX_PDEST_MSB:V11Q_EX_PDEST_LSB] !==
           expected_pdest) ||
          (dut.ex0_pdest_q !== expected_pdest))
        v11q_oracle_fail("alu-down-result");
      if ((dut.ex0_pre_auth_valid_w !== 1'b1) ||
          (dut.ex0_producer_open_w !== 1'b1) ||
          (dut.ex0_wb_valid_w !== 1'b1) ||
          (dut.wb0_producer_id_w !== V11Q_PID) ||
          (dut.wb0_data_w !== V11Q_ALU_RESULT))
        v11q_oracle_fail("alu-completion-authority");
      `TB_TICK(clk);
      #1;
      if ((dut.ex0_valid_q !== 1'b0) ||
          (dut.ex0_wb_valid_w !== 1'b0))
        v11q_oracle_fail("alu-one-cycle-death");
      $display("[V11Q-EX0-PACKET][PASS] pid=%0h result=%0h birth=1 death=1",
               V11Q_PID, V11Q_ALU_RESULT);
    end
  endtask

  task automatic v11q_stage_branch_packet;
    reg [PRODUCER_ID_W-1:0] raw_ex0_packet_pid;
    begin
      reset_dut();
      v11q_prime_identity();
      commit_ready = 1'b0;
      set_dispatch0(
          V11Q_BRANCH_PC, make_branch_ctrl(`CMP_OP_EQ),
          5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_npc = V11Q_BRANCH_PC + 64'd4;
      dispatch0_bht_idx = V11Q_BRANCH_BHT;
      dispatch0_pred_taken = 1'b1;
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11Q_PID))
        v11q_oracle_fail("branch-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.issue0_ctrlflow_fire_w !== 1'b1) ||
          (dut.ex0_up_valid_w !== 1'b1) ||
          (dut.issue0_resolve_emit_w !== 1'b1) ||
          (dut.ex0_up_producer_id_w !== V11Q_PID) ||
          (dut.iq_issue0_producer_id_w !== V11Q_PID))
        v11q_oracle_fail("branch-up-pair");
      `TB_TICK(clk);
      #1;
      if ((dut.ex0_valid_q !== 1'b1) ||
          (dut.branch_resolve_stage_valid_w !== 1'b1))
        v11q_oracle_fail("branch-stage-birth");
      raw_ex0_packet_pid = {
          dut.ex0_down_payload_w[
              V11Q_EX_GEN_MSB:V11Q_EX_GEN_LSB],
          dut.ex0_down_payload_w[
              V11Q_EX_ROB_MSB:V11Q_EX_ROB_LSB]
      };
      if ((raw_ex0_packet_pid !== V11Q_PID) ||
          (dut.ex0_producer_id_q !== V11Q_PID))
        v11q_oracle_fail("branch-ex0-packet-pid");
      if (dut.branch_resolve_payload_producer_id_w !== V11Q_PID)
        v11q_oracle_fail("branch-down-pid");
      if ((dut.branch_resolve_payload_pc_w !== V11Q_BRANCH_PC) ||
          (dut.branch_resolve_payload_next_pc_w !==
           V11Q_BRANCH_NEXT_PC) ||
          (dut.branch_resolve_payload_misaligned_w !== 1'b0) ||
          (dut.branch_resolve_payload_mispredict_w !== 1'b1) ||
          (dut.branch_resolve_payload_is_branch_w !== 1'b1) ||
          (dut.branch_resolve_payload_taken_w !== 1'b1) ||
          (dut.branch_resolve_payload_pred_taken_w !== 1'b1) ||
          (dut.branch_resolve_payload_bht_idx_w !==
           V11Q_BRANCH_BHT))
        v11q_oracle_fail("branch-down-payload");
      if ((dut.branch_resolve_rob_open_w !== 1'b1) ||
          (dut.branch_resolve_raw_ex0_coherent_w !== 1'b1))
        v11q_oracle_fail("branch-raw-coherence");
    end
  endtask

  task automatic v11q_run_branch_pair;
    begin
      v11q_stage_branch_packet();
      if ((dut.branch_resolve_authorized_w !== 1'b1) ||
          (branch_resolve_valid !== 1'b1) ||
          (branch_resolve_pc !== V11Q_BRANCH_PC) ||
          (branch_resolve_next_pc !== V11Q_BRANCH_NEXT_PC) ||
          (branch_resolve_rob_idx !==
           V11Q_PID[ROB_INDEX_W-1:0]) ||
          (branch_resolve_mispredict !== 1'b1))
        v11q_oracle_fail("branch-public-packet");

      // Keep the ROB query open and change only the raw EX0 generation.
      // Index-only coherence would incorrectly authorize this packet.
      force dut.ex0_producer_id_q = V11Q_WRONG_GEN_PID;
      #1;
      if ((dut.branch_resolve_rob_open_w !== 1'b1) ||
          (dut.branch_resolve_raw_ex0_coherent_w !== 1'b0) ||
          (dut.branch_resolve_authorized_w !== 1'b0))
        v11q_oracle_fail("branch-wrong-generation-fence");
      v11q_check_branch_silent("branch-wrong-generation-fence");
      rst = 1'b1;
      #1;
      release dut.ex0_producer_id_q;
      `TB_TICK(clk);
      rst = 1'b0;
      clear_dispatch();
      #1;
      $display("[V11Q-BRANCH-PAIR][PASS] pid=%0h raw_coherence=1 wrong_generation_rejected=1",
               V11Q_PID);
    end
  endtask

  task automatic v11q_run_death_edges;
    begin
      v11q_stage_branch_packet();
      force dut.branch_resolve_rob_open_w = 1'b1;
      force dut.ex0_producer_open_w = 1'b1;
      flush = 1'b1;
      #1;
      v11q_check_branch_silent("branch-flush-cut");
      if ((dut.ex0_pre_auth_valid_w !== 1'b0) ||
          (dut.ex0_wb_valid_w !== 1'b0))
        v11q_oracle_fail("ex0-flush-cut");
      `TB_TICK(clk);
      flush = 1'b0;
      release dut.branch_resolve_rob_open_w;
      release dut.ex0_producer_open_w;
      #1;
      if ((dut.branch_resolve_stage_valid_w !== 1'b0) ||
          (dut.ex0_valid_q !== 1'b0))
        v11q_oracle_fail("flush-next-cycle-empty");
      $display("[V11Q-DEATH-EDGES][PASS] branch_mask=1 ex0_mask=1 next_cycle_empty=1");
    end
  endtask

  task automatic run_v11q_int_lane0_packet_semantic;
    begin
      v11q_stage_alu_packet();
      v11q_run_branch_pair();
      v11q_run_death_edges();
      $display("[V11Q-INT-LANE0-PACKET-MATRIX][PASS] ex0_packet=1 ex0_alias=1 branch_packet=1 generation=1 index=2 wrong_generation=1 flush=1");
      reset_dut();
    end
  endtask
`endif
`ifdef V11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED
  task automatic v11p_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11P-CHECKPOINT-IRREVOCABLE-WRITE-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11p_check_tracker_exact;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [1:0] owner_kind;
    input [1023:0] stage;
    begin
      if ((dut.mem_owner_live_mask_w[token] !== 1'b1) ||
          (dut.mem_owner_kind_table_w[token*2 +: 2] !== owner_kind) ||
          (dut.mem_owner_epoch_table_w[token*2 +: 2] !== V11P_EPOCH) ||
          (dut.mem_owner_producer_id_table_w[
              token*PRODUCER_ID_W +: PRODUCER_ID_W] !== producer_id))
        v11p_oracle_fail(stage);
    end
  endtask

  task automatic v11p_check_holder;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [1023:0] stage;
    reg [(1 << PRODUCER_ID_W)-1:0] expected_mask;
    begin
      expected_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_mask[producer_id] = 1'b1;
      if ((dut.checkpoint_irrevocable_write_q !== 1'b1) ||
          (dut.checkpoint_irrevocable_write_pid_q !== producer_id) ||
          (dut.checkpoint_irrevocable_write_live_mask_w !==
           expected_mask) ||
          (dut.transient_producer_live_mask_w[producer_id] !== 1'b1) ||
          (dut.external_producer_live_mask_w[producer_id] !== 1'b1) ||
          (dut.producer_live_mask_w[producer_id] !== 1'b1))
        v11p_oracle_fail(stage);
    end
  endtask

  task automatic v11p_check_lane0_terminal;
    input [4:0] token;
    input [1:0] owner_kind;
    input [1023:0] stage;
    begin
      if ((dut.mem_terminal_ingress_valid_w[0] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[0] !== 1'b1) ||
          (dut.mem_terminal_ingress_kind_w[1:0] !== owner_kind) ||
          (dut.mem_terminal_ingress_token_w[4:0] !== token) ||
          (dut.mem_terminal_ingress_epoch_w[1:0] !== V11P_EPOCH))
        v11p_oracle_fail(stage);
    end
  endtask

  task automatic v11p_wait_token_dead;
    input [4:0] token;
    input [1023:0] stage;
    integer wait_cycle;
    begin
      wait_cycle = 0;
      while (((dut.mem_owner_live_mask_w[token] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[token] === 1'b1)) &&
             (wait_cycle < 12)) begin
        v11p_check_holder(V11P_PID, stage);
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((dut.mem_owner_live_mask_w[token] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[token] !== 1'b0))
        v11p_oracle_fail(stage);
    end
  endtask

  task automatic v11p_prime_identity;
    begin
      run_v8n_prime_producer_generation();
      force dut.u_mem_owner_tracker.next_token_q = V11P_TOKEN;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11P_TOKEN)
        v11p_oracle_fail("token-cursor-prime-force");
      release dut.u_mem_owner_tracker.next_token_q;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11P_TOKEN)
        v11p_oracle_fail("token-cursor-prime-release");
    end
  endtask

  task automatic v11p_request_restore;
    input [1023:0] stage;
    begin
      checkpoint_restore = 1'b1;
      #1;
      if ((dut.checkpoint_restore_apply_w !== 1'b0) ||
          (dut.checkpoint_restore_hold_w !== 1'b1))
        v11p_oracle_fail(stage);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      if ((dut.checkpoint_restore_pending_q !== 1'b1) ||
          (dut.checkpoint_restore_apply_w !== 1'b0))
        v11p_oracle_fail(stage);
    end
  endtask

  task automatic v11p_launch_store;
    integer wait_cycle;
    begin
      reset_dut();
      v11p_prime_identity();
      commit_ready = 1'b0;
      mem_translate_active = 1'b1;
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b0;

      set_dispatch0(
          V11P_STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
          5'd0, 5'd0, 5'd0, V11P_STORE_VA);
      dispatch0_inst = 32'h0000_3023;
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11P_PID))
        v11p_oracle_fail("store-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      wait_cycle = 0;
      while ((mem_req_valid !== 1'b1) && (wait_cycle < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((mem_req_valid !== 1'b1) ||
          (mem_req_write !== 1'b1) ||
          (mem_req_probe !== 1'b1) ||
          (mem_req_owner_kind !== V11P_STORE_KIND) ||
          (mem_req_owner_token !== V11P_TOKEN) ||
          (mem_req_mmu_epoch !== V11P_EPOCH))
        v11p_oracle_fail("store-probe-request");
      v11p_check_tracker_exact(
          V11P_PID, V11P_TOKEN, V11P_STORE_KIND,
          "store-probe-tracker");
      `TB_TICK(clk);
      #1;

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = V11P_STORE_PA;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.sq_fill_valid_w !== 1'b1))
        v11p_oracle_fail("store-probe-response");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      wait_cycle = 0;
      while ((mem_req_valid !== 1'b1) && (wait_cycle < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((mem_req_valid !== 1'b1) ||
          (mem_req_write !== 1'b1) ||
          (mem_req_probe !== 1'b0) ||
          (mem_req_pretrans !== 1'b1) ||
          (mem_req_nokill !== 1'b1) ||
          (mem_req_owner_kind !== V11P_STORE_KIND) ||
          (mem_req_owner_token !== V11P_TOKEN) ||
          (dut.checkpoint_irrevocable_write_launch_w !== 1'b1) ||
          (dut.checkpoint_irrevocable_write_launch_pid_w !== V11P_PID))
        v11p_oracle_fail("store-launch-edge");
      `TB_TICK(clk);
      #1;
      v11p_check_holder(V11P_PID, "store-holder-birth");
      v11p_check_tracker_exact(
          V11P_PID, V11P_TOKEN, V11P_STORE_KIND,
          "store-holder-birth");
      if ((dut.sq_snoop_request_sent_w !== 1) ||
          (dut.miq_count_w !== 1))
        v11p_oracle_fail("store-holder-birth");
    end
  endtask

  task automatic v11p_run_store_lifecycle;
    integer hold_cycle;
    begin
      v11p_launch_store();
      v11p_request_restore("store-restore-gate");
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        v11p_check_holder(V11P_PID, "store-preterminal-hold");
        v11p_check_tracker_exact(
            V11P_PID, V11P_TOKEN, V11P_STORE_KIND,
            "store-preterminal-hold");
        `TB_TICK(clk);
        #1;
      end

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.miq_drain_rsp_fire_w !== 1'b1) ||
          (dut.miq_drain_wb_fire_w !== 1'b1) ||
          (commit0_valid !== 1'b0)) begin
        $display("[V11P-STORE-TERMINAL-DIAG] ready=%b drain_rsp=%b drain_wb=%b commit0=%b miq_kind=%b token=%0d",
                 mem_rsp_ready, dut.miq_drain_rsp_fire_w,
                 dut.miq_drain_wb_fire_w, commit0_valid,
                 dut.miq_head_kind_w, dut.miq_head_owner_token_w);
        v11p_oracle_fail("store-terminal-edge");
      end
      if (dut.mem_terminal_ingress_valid_w[0] !== 1'b0)
        v11p_oracle_fail("store-terminal-edge");
      v11p_check_holder(V11P_PID, "store-terminal-edge");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      v11p_check_holder(V11P_PID, "store-post-terminal-holder");
      if ((dut.sq_snoop_terminal_w !== 1) ||
          (dut.checkpoint_restore_apply_w !== 1'b0))
        v11p_oracle_fail("store-post-terminal-holder");

      commit_ready = 1'b1;
      #1;
      if ((commit0_valid !== 1'b1) ||
          (commit0_producer_id !== V11P_PID) ||
          (dut.checkpoint_irrevocable_write_retire_w !== 1'b1) ||
          (dut.sq_release_fire_w !== 1'b1) ||
          (commit1_valid !== 1'b0) ||
          (dut.checkpoint_restore_apply_w !== 1'b0))
        v11p_oracle_fail("store-exact-retire-edge");
      `TB_TICK(clk);
      #1;
      if ((dut.checkpoint_irrevocable_write_q !== 1'b0) ||
          (dut.checkpoint_irrevocable_write_pid_q !==
           {PRODUCER_ID_W{1'b0}}) ||
          (dut.sq_count_w !== 0) ||
          (dut.checkpoint_restore_apply_w !== 1'b1))
        v11p_oracle_fail("store-exact-retire-clear");
      `TB_TICK(clk);
      #1;
      if ((dut.checkpoint_restore_apply_w !== 1'b0) ||
          (dut.checkpoint_restore_pending_q !== 1'b0) ||
          (rob_count !== 0))
        v11p_oracle_fail("store-restore-complete");
      $display("[V11P-STORE-LIFECYCLE][PASS] pid=%0h token=%0d birth=1 hold=2 terminal=1 lane0_retire=1 restore=1",
               V11P_PID, V11P_TOKEN);
    end
  endtask

  task automatic v11p_launch_amo_write;
    integer wait_cycle;
    begin
      reset_dut();
      v11p_prime_identity();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      set_dispatch0(
          V11P_AMO_PC,
          make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
          5'd0, 5'd0, 5'd20, 64'd0);
      dispatch0_inst =
          inst_amo(5'b00000, 5'd0, 5'd0, `FUNCT3_LD, 5'd20);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11P_PID))
        v11p_oracle_fail("amo-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      wait_cycle = 0;
      while ((mem_req_valid !== 1'b1) && (wait_cycle < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((mem_req_valid !== 1'b1) ||
          (mem_req_write !== 1'b0) ||
          (mem_req_owner_kind !== V11P_ATOMIC_KIND) ||
          (mem_req_owner_token !== V11P_TOKEN))
        v11p_oracle_fail("amo-read-request");
      v11p_check_tracker_exact(
          V11P_PID, V11P_TOKEN, V11P_ATOMIC_KIND,
          "amo-read-request");
      mem_req_ready = 1'b1;
      #1;
      if ((dut.issue0_mem_request_fire_w !== 1'b1) ||
          (dut.miq_push_valid_w !== 1'b1))
        v11p_oracle_fail("amo-read-request");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = V11P_AMO_READ_VALUE;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_amo_read_rsp_w !== 1'b1) ||
          (dut.mem_rsp_final_fire_w !== 1'b0))
        v11p_oracle_fail("amo-read-response");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      if ((dut.mem_pending_q !== 1'b1) ||
          (dut.mem_amo_write_phase_q !== 1'b1) ||
          (dut.mem_producer_id_q !== V11P_PID) ||
          (dut.mem_owner_token_q !== V11P_TOKEN) ||
          (mem_req_valid !== 1'b1) ||
          (mem_req_write !== 1'b1))
        v11p_oracle_fail("amo-write-visible");

      mem_req_ready = 1'b1;
      #1;
      if ((dut.push_amo_write_w !== 1'b1) ||
          (dut.checkpoint_irrevocable_write_launch_w !== 1'b1) ||
          (dut.checkpoint_irrevocable_write_launch_pid_w !== V11P_PID))
        v11p_oracle_fail("amo-launch-edge");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      v11p_check_holder(V11P_PID, "amo-holder-birth");
      v11p_check_tracker_exact(
          V11P_PID, V11P_TOKEN, V11P_ATOMIC_KIND,
          "amo-holder-birth");
      if ((dut.mem_amo_write_sent_q !== 1'b1) ||
          (dut.miq_count_w !== 1))
        v11p_oracle_fail("amo-holder-birth");
    end
  endtask

  task automatic v11p_run_amo_lifecycle;
    integer hold_cycle;
    begin
      v11p_launch_amo_write();
      v11p_request_restore("amo-restore-gate");
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        v11p_check_holder(V11P_PID, "amo-preterminal-hold");
        v11p_check_tracker_exact(
            V11P_PID, V11P_TOKEN, V11P_ATOMIC_KIND,
            "amo-preterminal-hold");
        `TB_TICK(clk);
        #1;
      end

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_rsp_final_fire_w !== 1'b1) ||
          (dut.mem_wb_fire_w !== 1'b1) ||
          (commit0_valid !== 1'b0)) begin
        $display("[V11P-AMO-TERMINAL-DIAG] ready=%b final=%b mem_wb=%b commit0=%b miq_kind=%b token=%0d",
                 mem_rsp_ready, dut.mem_rsp_final_fire_w,
                 dut.mem_wb_fire_w, commit0_valid,
                 dut.miq_head_kind_w, dut.miq_head_owner_token_w);
        v11p_oracle_fail("amo-terminal-edge");
      end
      v11p_check_lane0_terminal(
          V11P_TOKEN, V11P_ATOMIC_KIND, "amo-terminal-edge");
      v11p_check_holder(V11P_PID, "amo-terminal-edge");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      v11p_check_holder(V11P_PID, "amo-post-terminal-holder");
      v11p_wait_token_dead(
          V11P_TOKEN, "amo-post-terminal-tracker-death");
      v11p_check_holder(
          V11P_PID, "amo-post-terminal-tracker-death");
      if (dut.checkpoint_restore_apply_w !== 1'b0)
        v11p_oracle_fail("amo-post-terminal-tracker-death");

      commit_ready = 1'b1;
      #1;
      if ((commit0_valid !== 1'b1) ||
          (commit0_producer_id !== V11P_PID) ||
          (dut.checkpoint_irrevocable_write_retire_w !== 1'b1) ||
          (commit1_valid !== 1'b0) ||
          (dut.checkpoint_restore_apply_w !== 1'b0))
        v11p_oracle_fail("amo-exact-retire-edge");
      `TB_TICK(clk);
      #1;
      if ((dut.checkpoint_irrevocable_write_q !== 1'b0) ||
          (dut.checkpoint_irrevocable_write_pid_q !==
           {PRODUCER_ID_W{1'b0}}) ||
          (dut.checkpoint_restore_apply_w !== 1'b1))
        v11p_oracle_fail("amo-exact-retire-clear");
      `TB_TICK(clk);
      #1;
      if ((dut.checkpoint_restore_apply_w !== 1'b0) ||
          (dut.checkpoint_restore_pending_q !== 1'b0) ||
          (rob_count !== 0))
        v11p_oracle_fail("amo-restore-complete");
      $display("[V11P-AMO-LIFECYCLE][PASS] pid=%0h token=%0d birth=1 hold=2 terminal=1 tracker_dead_before_retire=1 lane0_retire=1 restore=1",
               V11P_PID, V11P_TOKEN);
    end
  endtask

  task automatic v11p_run_wrong_generation_retire_guard;
    begin
      v11p_launch_store();
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.miq_drain_rsp_fire_w !== 1'b1))
        v11p_oracle_fail("wrong-generation-terminal");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      commit_ready = 1'b1;
      #1;
      if ((commit0_valid !== 1'b1) ||
          (commit0_producer_id !== V11P_PID))
        v11p_oracle_fail("wrong-generation-retire-precondition");
      force dut.rob_commit0_producer_id_w = V11P_WRONG_GEN_PID;
      #1;
      if (dut.checkpoint_irrevocable_write_retire_w !== 1'b0)
        v11p_oracle_fail("wrong-generation-retire-guard");
      `TB_TICK(clk);
      release dut.rob_commit0_producer_id_w;
      #1;
      v11p_check_holder(V11P_PID, "wrong-generation-retire-hold");
      $display("[V11P-WRONG-GENERATION-RETIRE-GUARD][PASS] holder_pid=%0h injected_commit_pid=%0h retained=1",
               V11P_PID, V11P_WRONG_GEN_PID);
      reset_dut();
    end
  endtask

  task automatic run_v11p_checkpoint_irrevocable_write_semantic;
    begin
      tb_check32("V11P production dual-memory parameter",
                 TB_ENABLE_DUAL_MEM, 32'd1);
      v11p_run_store_lifecycle();
      v11p_run_amo_lifecycle();
      v11p_run_wrong_generation_retire_guard();
      $display("[V11P-CHECKPOINT-IRREVOCABLE-WRITE-MATRIX][PASS] store=1 amo=1 generation=1 widths=2 hold=4 terminal=2 tracker_pre_retire_death=1 exact_lane0_retire=2 wrong_generation_guard=1 restore=2");
      reset_dut();
    end
  endtask
`endif
`ifdef V11O_MEMORY_BUFFER_TOKEN_FOCUSED
  task automatic v11o_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11O-MEMORY-BUFFER-TOKEN-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11o_check_tracker_live;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [1:0] owner_kind;
    input [1023:0] stage;
    begin
      if ((dut.mem_owner_live_mask_w[token] !== 1'b1) ||
          (dut.mem_owner_kind_table_w[token*2 +: 2] !== owner_kind) ||
          (dut.mem_owner_epoch_table_w[token*2 +: 2] !== V11O_EPOCH) ||
          (dut.mem_owner_producer_id_table_w[
              token*PRODUCER_ID_W +: PRODUCER_ID_W] !== producer_id))
        v11o_oracle_fail(stage);
    end
  endtask

  task automatic v11o_check_buffer;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [`XLEN-1:0] address;
    input [1023:0] stage;
    begin
      if ((dut.mem_buffer_valid_q !== 1'b1) ||
          (dut.mem_buffer_rob_idx_q !==
           producer_id[ROB_INDEX_W-1:0]) ||
          (dut.mem_buffer_load_q !== 1'b1) ||
          (dut.mem_buffer_store_q !== 1'b0) ||
          (dut.mem_buffer_eff_addr_q !== address) ||
          (dut.mem_buffer_fault_tval_q !== address) ||
          (dut.mem_buffer_owner_kind_q !== V11O_LOAD_KIND) ||
          (dut.mem_buffer_owner_token_q !== token) ||
          (dut.mem_buffer_mmu_epoch_q !== V11O_EPOCH))
        v11o_oracle_fail(stage);
      v11o_check_tracker_live(
          producer_id, token, V11O_LOAD_KIND, stage);
    end
  endtask

  task automatic v11o_check_terminal_lane;
    input integer expected_lane;
    input [4:0] token;
    input [1:0] owner_kind;
    input [1023:0] stage;
    integer lane;
    integer matching_lanes;
    begin
      matching_lanes = 0;
      for (lane = 0; lane < 10; lane = lane + 1) begin
        if ((dut.mem_terminal_ingress_valid_w[lane] === 1'b1) &&
            (dut.mem_terminal_ingress_token_w[lane*5 +: 5] === token))
          matching_lanes = matching_lanes + 1;
      end
      if ((matching_lanes != 1) ||
          (dut.mem_terminal_ingress_valid_w[expected_lane] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[expected_lane] !== 1'b1) ||
          (dut.mem_terminal_ingress_kind_w[
              expected_lane*2 +: 2] !== owner_kind) ||
          (dut.mem_terminal_ingress_token_w[
              expected_lane*5 +: 5] !== token) ||
          (dut.mem_terminal_ingress_epoch_w[
              expected_lane*2 +: 2] !== V11O_EPOCH))
        v11o_oracle_fail(stage);
    end
  endtask

  task automatic v11o_wait_token_dead;
    input [4:0] token;
    input [1023:0] stage;
    integer wait_cycle;
    begin
      wait_cycle = 0;
      while (((dut.mem_owner_live_mask_w[token] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[token] === 1'b1)) &&
             (wait_cycle < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((dut.mem_owner_live_mask_w[token] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[token] !== 1'b0))
        v11o_oracle_fail(stage);
    end
  endtask

  task automatic v11o_prime_identity;
    begin
      run_v8n_prime_producer_generation();
      force dut.u_mem_owner_tracker.next_token_q = V11O_TOKEN_OLD;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11O_TOKEN_OLD)
        v11o_oracle_fail("token-cursor-prime-force");
      release dut.u_mem_owner_tracker.next_token_q;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11O_TOKEN_OLD)
        v11o_oracle_fail("token-cursor-prime-release");
    end
  endtask

  task automatic v11o_seed_legacy_buffer;
    input create_branch_boundary;
    input [PRODUCER_ID_W-1:0] expected_load_pid;
    input [`XLEN-1:0] load_pc;
    input [`XLEN-1:0] load_address;
    integer hold_cycle;
    begin
      reset_dut();
      v11o_prime_identity();
      commit_ready = !create_branch_boundary;
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b0;

      set_dispatch0(
          V11O_LR_PC,
          make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
          5'd0, 5'd0, 5'd20, V11O_LR_ADDRESS);
      dispatch0_inst =
          inst_amo(5'b00010, 5'd0, 5'd0, `FUNCT3_LD, 5'd20);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11O_PID_OLD))
        v11o_oracle_fail("legacy-lr-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("legacy-lr-reservation-capture");
      `TB_TICK(clk);
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue_res_producer_id_q !== V11O_PID_OLD) ||
          (dut.mem_issue_res_owner_kind_q !== V11O_ATOMIC_KIND) ||
          (dut.mem_issue_res_owner_token_q !== V11O_TOKEN_OLD) ||
          (mem_req_valid !== 1'b1) ||
          (mem_req_owner_token !== V11O_TOKEN_OLD) ||
          (dut.miq_push_owner_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("legacy-lr-request-fire");
      `TB_TICK(clk);
      #1;
      if ((dut.mem_pending_q !== 1'b1) ||
          (dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("legacy-lr-pending");
      v11o_check_tracker_live(
          V11O_PID_OLD, V11O_TOKEN_OLD, V11O_ATOMIC_KIND,
          "legacy-lr-tracker-live");

      if (create_branch_boundary) begin
        set_dispatch0(
            V11O_BRANCH_PC, make_branch_ctrl(`CMP_OP_EQ),
            5'd0, 5'd0, 5'd0, 64'd8);
        dispatch0_pred_taken = 1'b1;
        dispatch0_pred_npc = V11O_BRANCH_PC + 64'd8;
        #1;
        if ((dispatch0_ready !== 1'b1) ||
            (dispatch0_producer_id !== V11O_PID_BRANCH))
          v11o_oracle_fail("branch-boundary-dispatch");
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        if (dut.issue0_ctrlflow_fire_w !== 1'b1)
          v11o_oracle_fail("branch-boundary-fire");
        t3v_force_branch_rob = dut.issue0_rob_idx_w;
        `TB_TICK(clk);
        #1;
        if ((branch_resolve_valid !== 1'b1) ||
            (branch_resolve_mispredict !== 1'b0))
          v11o_oracle_fail("branch-boundary-initial-resolve");
        `TB_TICK(clk);
        #1;
      end

      set_dispatch0(
          load_pc, make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
          5'd0, 5'd0, 5'd21, load_address);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== expected_load_pid))
        v11o_oracle_fail("buffer-load-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("buffer-load-reservation-capture");
      `TB_TICK(clk);
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue_res_producer_id_q !== expected_load_pid) ||
          (dut.mem_issue_res_owner_token_q !== V11O_TOKEN_BUFFER) ||
          (dut.issue0_mem_buffer_fire_w !== 1'b1) ||
          (dut.issue0_mem_request_fire_w !== 1'b0)) begin
        $display("[V11O-BIRTH-DIAG] valid=%b pid=%h expected_pid=%h token=%h expected_token=%h buffer_fire=%b request_fire=%b is_mem=%b is_amo=%b exception=%b sq_fwd=%b consume=%b pending=%b miq_count=%0d",
                 dut.mem_issue_res_valid_q,
                 dut.mem_issue_res_producer_id_q, expected_load_pid,
                 dut.mem_issue_res_owner_token_q, V11O_TOKEN_BUFFER,
                 dut.issue0_mem_buffer_fire_w,
                 dut.issue0_mem_request_fire_w, dut.issue0_is_mem_w,
                 dut.issue0_is_amo_w, dut.issue0_mem_exception_w,
                 dut.issue0_sq_fwd_w, dut.mem_issue_res_consume_fire_w,
                 dut.mem_pending_q, dut.miq_count_w);
        v11o_oracle_fail("legacy-buffer-birth-fire");
      end
      `TB_TICK(clk);
      #1;
      v11o_check_buffer(
          expected_load_pid, V11O_TOKEN_BUFFER, load_address,
          "legacy-buffer-birth");
      if (dut.mem_buffer_req_valid_w !== 1'b0)
        v11o_oracle_fail("legacy-buffer-old-owner-block");
      for (hold_cycle = 0; hold_cycle < 3;
           hold_cycle = hold_cycle + 1) begin
        v11o_check_buffer(
            expected_load_pid, V11O_TOKEN_BUFFER, load_address,
            "legacy-buffer-hold");
        if ((dut.mem_buffer_req_valid_w !== 1'b0) ||
            (mem_req_valid !== 1'b0))
          v11o_oracle_fail("legacy-buffer-hold-blocked");
        `TB_TICK(clk);
        #1;
      end
      $display("[V11O-LEGACY-BIRTH-HOLD][PASS] pid=%0h token=%0d cycles=3",
               expected_load_pid, V11O_TOKEN_BUFFER);
    end
  endtask

  task automatic v11o_complete_old_lr;
    begin
      mem_req_ready = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0123_4567_89ab_cdef;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_rsp_final_fire_w !== 1'b1) ||
          (dut.miq_pop_w !== 1'b1))
        v11o_oracle_fail("old-lr-final-response");
      v11o_check_terminal_lane(
          0, V11O_TOKEN_OLD, V11O_ATOMIC_KIND,
          "old-lr-lane0-terminal");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      if ((dut.mem_pending_q !== 1'b0) || (dut.miq_count_w !== 0))
        v11o_oracle_fail("old-lr-next-cycle-clear");
      v11o_wait_token_dead(
          V11O_TOKEN_OLD, "old-lr-tracker-death");
    end
  endtask

  task automatic v11o_unused_load_blocked_probe;
    integer lane;
    begin
      if (TB_ENABLE_DUAL_MEM != 0)
        v11o_oracle_fail("legacy-testbench-parameter");

      // A. Natural legacy LR blocking creates the buffer.  The younger load
      // retains stimulus-owned token 29 across three cycles, transfers the
      // exact tuple to MIQ, and finally dies through collector lane0.
      v11o_seed_legacy_buffer(
          1'b0, V11O_PID_TRANSFER, V11O_TRANSFER_PC,
          V11O_TRANSFER_ADDRESS);
      v11o_complete_old_lr();
      mem_req_ready = 1'b1;
      #1;
      v11o_check_buffer(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER,
          V11O_TRANSFER_ADDRESS, "buffer-transfer-edge-holder");
      if ((dut.mem_buffer_req_valid_w !== 1'b1) ||
          (dut.mem_buffer_req_fire_w !== 1'b1) ||
          (mem_req_valid !== 1'b1) ||
          (mem_req_owner_kind !== V11O_LOAD_KIND) ||
          (mem_req_owner_token !== V11O_TOKEN_BUFFER) ||
          (mem_req_mmu_epoch !== V11O_EPOCH) ||
          (dut.miq_push_valid_w !== 1'b1) ||
          (dut.miq_push_owner_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("buffer-transfer-request");
      for (lane = 0; lane < 10; lane = lane + 1)
        if ((dut.mem_terminal_ingress_valid_w[lane] === 1'b1) &&
            (dut.mem_terminal_ingress_token_w[lane*5 +: 5] ===
             V11O_TOKEN_BUFFER))
          v11o_oracle_fail("buffer-transfer-is-not-terminal");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.mem_buffer_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_kind_w !== V11O_LOAD_KIND) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("buffer-transfer-next-cycle-clear");
      v11o_check_tracker_live(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER, V11O_LOAD_KIND,
          "buffer-transfer-miq-holder");
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'hfeed_face_cafe_babe;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_rsp_final_fire_w !== 1'b1))
        v11o_oracle_fail("buffer-load-final-response");
      v11o_check_terminal_lane(
          0, V11O_TOKEN_BUFFER, V11O_LOAD_KIND,
          "buffer-load-lane0-terminal");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      if (dut.miq_count_w !== 0)
        v11o_oracle_fail("buffer-load-miq-clear");
      v11o_wait_token_dead(
          V11O_TOKEN_BUFFER, "buffer-load-tracker-death");
      $display("[V11O-LEGACY-TRANSFER-LANE0-DEATH][PASS] token=%0d",
               V11O_TOKEN_BUFFER);

      // B. A real older branch boundary plus a delayed mispredict cancels a
      // resident younger load before an otherwise-ready buffer request.  The
      // exact token is accepted once at collector lane8 and then dies.
      v11o_seed_legacy_buffer(
          1'b1, V11O_PID_CANCEL, V11O_CANCEL_PC,
          V11O_CANCEL_ADDRESS);
      v11o_complete_old_lr();
      mem_req_ready = 1'b1;
      #1;
      if ((dut.mem_buffer_req_valid_w !== 1'b1) ||
          (dut.mem_buffer_req_fire_w !== 1'b1))
        v11o_oracle_fail("cancel-open-slot-precondition");
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      #1;
      v11o_check_buffer(
          V11O_PID_CANCEL, V11O_TOKEN_BUFFER,
          V11O_CANCEL_ADDRESS, "buffer-cancel-edge-holder");
      if ((dut.mem_buffer_kill_w !== 1'b1) ||
          (dut.mem_buffer_cancel_w !== 1'b1) ||
          (dut.mem_buffer_req_fire_w !== 1'b0) ||
          (mem_req_valid !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b0))
        v11o_oracle_fail("buffer-selective-cancel");
      v11o_check_terminal_lane(
          8, V11O_TOKEN_BUFFER, V11O_LOAD_KIND,
          "buffer-cancel-lane8");
      `TB_TICK(clk);
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      if ((dut.mem_buffer_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 0) ||
          (mem_req_valid !== 1'b0))
        v11o_oracle_fail("buffer-cancel-next-cycle-clear");
      v11o_wait_token_dead(
          V11O_TOKEN_BUFFER, "buffer-cancel-tracker-death");
      $display("[V11O-LEGACY-CANCEL-LANE8-DEATH][PASS] token=%0d",
               V11O_TOKEN_BUFFER);

      $display("[V11O-MEMORY-BUFFER-TOKEN-MATRIX][PASS] legacy_birth=2 hold_cycles=6 transfer=1 lane0_terminal=1 lane8_cancel=1 tracker_death=2 product_reachability=external");
      reset_dut();
    end
  endtask

  task automatic v11o_check_store_buffer;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [`XLEN-1:0] address;
    input [1023:0] stage;
    begin
      if ((dut.mem_buffer_valid_q !== 1'b1) ||
          (dut.mem_buffer_rob_idx_q !==
           producer_id[ROB_INDEX_W-1:0]) ||
          (dut.mem_buffer_load_q !== 1'b0) ||
          (dut.mem_buffer_store_q !== 1'b1) ||
          (dut.mem_buffer_eff_addr_q !== address) ||
          (dut.mem_buffer_fault_tval_q !== address) ||
          (dut.mem_buffer_owner_kind_q !== V11O_STORE_KIND) ||
          (dut.mem_buffer_owner_token_q !== token) ||
          (dut.mem_buffer_mmu_epoch_q !== V11O_EPOCH))
        v11o_oracle_fail(stage);
      v11o_check_tracker_live(
          producer_id, token, V11O_STORE_KIND, stage);
    end
  endtask

  task automatic v11o_wait_request;
    input [`XLEN-1:0] address;
    input [4:0] token;
    input expect_probe;
    input [1023:0] stage;
    integer wait_cycle;
    begin
      wait_cycle = 0;
      while ((mem_req_valid !== 1'b1) && (wait_cycle < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((mem_req_valid !== 1'b1) ||
          (mem_req_addr !== address) ||
          (mem_req_probe !== expect_probe) ||
          (mem_req_owner_kind !== V11O_STORE_KIND) ||
          (mem_req_owner_token !== token) ||
          (mem_req_mmu_epoch !== V11O_EPOCH))
        v11o_oracle_fail(stage);
    end
  endtask

  task automatic v11o_seed_store0_filled;
    begin
      set_dispatch0(
          V11O_LR_PC, make_store_ctrl(`MEM_SIZE_DWORD),
          5'd0, 5'd0, 5'd0, V11O_STORE0_VA);
      dispatch0_inst = 32'h0000_3023;
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11O_PID_OLD))
        v11o_oracle_fail("store0-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("store0-reservation-capture");
      v11o_wait_request(
          V11O_STORE0_VA, V11O_TOKEN_OLD, 1'b1,
          "store0-probe-request");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("store0-probe-miq");
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = V11O_STORE0_PA;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_OLD) ||
          (dut.sq_fill_valid_w !== 1'b1))
        v11o_oracle_fail("store0-probe-response");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      if ((dut.sq_drain_valid_w !== 1'b1) ||
          (dut.grant_sq_w !== 1'b1) ||
          (dut.sq_drain_req_fire_w !== 1'b0))
        v11o_oracle_fail("store0-filled-sq-priority");
      v11o_check_tracker_live(
          V11O_PID_OLD, V11O_TOKEN_OLD, V11O_STORE_KIND,
          "store0-filled-tracker");
    end
  endtask

  task automatic v11o_transfer_store_buffer;
    integer hold_cycle;
    begin
      reset_dut();
      v11o_prime_identity();
      mem_translate_active = 1'b1;
      commit_ready = 1'b1;
      mem_req_ready = 1'b1;

      set_dispatch0(
          V11O_LR_PC, make_store_ctrl(`MEM_SIZE_DWORD),
          5'd0, 5'd0, 5'd0, V11O_STORE0_VA);
      dispatch0_inst = 32'h0000_3023;
      set_dispatch1(
          V11O_TRANSFER_PC, make_store_ctrl(`MEM_SIZE_DWORD),
          5'd0, 5'd0, 5'd0, V11O_STORE1_TRANSFER_VA);
      dispatch1_inst = 32'h0000_3023;
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11O_PID_OLD) ||
          (dut.dispatch1_producer_id_w !== V11O_PID_TRANSFER))
        v11o_oracle_fail("transfer-pair-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11O_TOKEN_OLD) ||
          (dut.mem_owner_alloc1_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("transfer-pair-allocation");
      v11o_wait_request(
          V11O_STORE0_VA, V11O_TOKEN_OLD, 1'b1,
          "transfer-store0-probe");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("transfer-store0-miq");
      if ((dut.mem_issue1_res_valid_q !== 1'b1) ||
          (dut.mem_issue1_res_producer_id_q !== V11O_PID_TRANSFER) ||
          (dut.mem_issue1_res_owner_token_q !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("transfer-store1-reservation");

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = V11O_STORE0_PA;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.sq_fill_valid_w !== 1'b1))
        v11o_oracle_fail("transfer-store0-probe-response");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;
      if ((dut.grant_sq_w !== 1'b1) ||
          (mem_req_owner_token !== V11O_TOKEN_OLD) ||
          (dut.issue1_mem_buffer_fire_w !== 1'b1) ||
          (dut.issue1_mem_request_fire_w !== 1'b0) ||
          (dut.mem_issue1_res_owner_token_q !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("lane1-buffer-birth-fire");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      v11o_check_store_buffer(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER,
          V11O_STORE1_TRANSFER_VA, "lane1-buffer-birth");
      for (hold_cycle = 0; hold_cycle < 3;
           hold_cycle = hold_cycle + 1) begin
        v11o_check_store_buffer(
            V11O_PID_TRANSFER, V11O_TOKEN_BUFFER,
            V11O_STORE1_TRANSFER_VA, "lane1-buffer-hold");
        if (dut.mem_buffer_req_fire_w !== 1'b0)
          v11o_oracle_fail("lane1-buffer-backpressure");
        `TB_TICK(clk);
        #1;
      end
      $display("[V11O-LEGACY-BIRTH-HOLD][PASS] lane=1 pid=%0h token=%0d cycles=3",
               V11O_PID_TRANSFER, V11O_TOKEN_BUFFER);

      mem_req_ready = 1'b1;
      #1;
      v11o_check_store_buffer(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER,
          V11O_STORE1_TRANSFER_VA, "buffer-transfer-edge-holder");
      if ((dut.mem_buffer_req_valid_w !== 1'b1) ||
          (dut.mem_buffer_req_fire_w !== 1'b1) ||
          (mem_req_probe !== 1'b1) ||
          (mem_req_owner_kind !== V11O_STORE_KIND) ||
          (mem_req_owner_token !== V11O_TOKEN_BUFFER) ||
          (dut.miq_push_valid_w !== 1'b1) ||
          (dut.miq_push_owner_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("buffer-transfer-request");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.mem_buffer_valid_q !== 1'b0) ||
          (dut.miq_occupancy_token_mask_w[V11O_TOKEN_BUFFER] !== 1'b1))
        v11o_oracle_fail("buffer-transfer-next-cycle-clear");
      v11o_check_tracker_live(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER, V11O_STORE_KIND,
          "buffer-transfer-miq-holder");

      // Complete store0 B/commit, then store1 probe, physical write, B and
      // commit.  Token29 must remain live through every authority handoff.
      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_OLD))
        v11o_oracle_fail("transfer-store0-b");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      if (commit0_valid !== 1'b1)
        v11o_oracle_fail("transfer-store0-commit");
      v11o_check_tracker_live(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER, V11O_STORE_KIND,
          "transfer-store1-before-probe-response");

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = V11O_STORE1_TRANSFER_PA;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_BUFFER) ||
          (dut.sq_fill_valid_w !== 1'b1))
        v11o_oracle_fail("transfer-store1-probe-response");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;
      if ((dut.grant_sq_w !== 1'b1) ||
          (mem_req_owner_token !== V11O_TOKEN_BUFFER) ||
          (mem_req_addr !== V11O_STORE1_TRANSFER_PA) ||
          (mem_req_pretrans !== 1'b1))
        v11o_oracle_fail("transfer-store1-physical-write");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      v11o_check_tracker_live(
          V11O_PID_TRANSFER, V11O_TOKEN_BUFFER, V11O_STORE_KIND,
          "transfer-store1-post-write");
      mem_rsp_valid = 1'b1;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.miq_head_owner_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("transfer-store1-b");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      if (commit0_valid !== 1'b1)
        v11o_oracle_fail("transfer-store1-commit");
      `TB_TICK(clk);
      #1;
      v11o_wait_token_dead(
          V11O_TOKEN_BUFFER, "transfer-store1-tracker-death");
      $display("[V11O-LEGACY-TRANSFER-SQ-DEATH][PASS] lane=1 token=%0d",
               V11O_TOKEN_BUFFER);
    end
  endtask

  task automatic v11o_cancel_store_buffer;
    integer hold_cycle;
    integer lane;
    begin
      reset_dut();
      v11o_prime_identity();
      mem_translate_active = 1'b1;
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      v11o_seed_store0_filled();

      set_dispatch0(
          V11O_BRANCH_PC, make_branch_ctrl(`CMP_OP_EQ),
          5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_taken = 1'b1;
      dispatch0_pred_npc = V11O_BRANCH_PC + 64'd8;
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11O_PID_BRANCH))
        v11o_oracle_fail("cancel-branch-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (dut.issue0_ctrlflow_fire_w !== 1'b1)
        v11o_oracle_fail("cancel-branch-fire");
      t3v_force_branch_rob = dut.issue0_rob_idx_w;
      `TB_TICK(clk);
      #1;
      if ((branch_resolve_valid !== 1'b1) ||
          (branch_resolve_mispredict !== 1'b0))
        v11o_oracle_fail("cancel-branch-initial-resolve");
      `TB_TICK(clk);
      #1;

      set_dispatch0(
          V11O_CANCEL_PC, make_store_ctrl(`MEM_SIZE_DWORD),
          5'd0, 5'd0, 5'd0, V11O_STORE1_CANCEL_VA);
      dispatch0_inst = 32'h0000_3023;
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11O_PID_CANCEL))
        v11o_oracle_fail("cancel-store1-dispatch");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11O_TOKEN_BUFFER))
        v11o_oracle_fail("cancel-store1-allocation");
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue_res_owner_token_q !== V11O_TOKEN_BUFFER) ||
          (dut.grant_sq_w !== 1'b1) ||
          (dut.issue0_mem_buffer_fire_w !== 1'b1) ||
          (dut.issue0_mem_request_fire_w !== 1'b0))
        v11o_oracle_fail("lane0-buffer-birth-fire");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      v11o_check_store_buffer(
          V11O_PID_CANCEL, V11O_TOKEN_BUFFER,
          V11O_STORE1_CANCEL_VA, "lane0-buffer-birth");
      for (hold_cycle = 0; hold_cycle < 3;
           hold_cycle = hold_cycle + 1) begin
        v11o_check_store_buffer(
            V11O_PID_CANCEL, V11O_TOKEN_BUFFER,
            V11O_STORE1_CANCEL_VA, "lane0-buffer-hold");
        if (dut.mem_buffer_req_fire_w !== 1'b0)
          v11o_oracle_fail("lane0-buffer-backpressure");
        `TB_TICK(clk);
        #1;
      end
      $display("[V11O-LEGACY-BIRTH-HOLD][PASS] lane=0 pid=%0h token=%0d cycles=3",
               V11O_PID_CANCEL, V11O_TOKEN_BUFFER);

      mem_req_ready = 1'b1;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      #1;
      v11o_check_store_buffer(
          V11O_PID_CANCEL, V11O_TOKEN_BUFFER,
          V11O_STORE1_CANCEL_VA, "buffer-cancel-edge-holder");
      if ((dut.mem_buffer_kill_w !== 1'b1) ||
          (dut.mem_buffer_cancel_w !== 1'b1) ||
          (dut.mem_buffer_req_fire_w !== 1'b0) ||
          (dut.mem_buffer_store_authority_end_mask_w !==
           (32'b1 << V11O_TOKEN_BUFFER)) ||
          (dut.sq_owner_release_effective_mask_w[V11O_TOKEN_BUFFER] !==
           1'b1) ||
          ((dut.miq_push_valid_w === 1'b1) &&
           (dut.miq_push_owner_token_w === V11O_TOKEN_BUFFER)))
        v11o_oracle_fail("buffer-selective-cancel");
      for (lane = 0; lane < 10; lane = lane + 1)
        if ((dut.mem_terminal_ingress_valid_w[lane] === 1'b1) &&
            (dut.mem_terminal_ingress_token_w[lane*5 +: 5] ===
             V11O_TOKEN_BUFFER))
          v11o_oracle_fail("store-cancel-uses-authority-end");
      `TB_TICK(clk);
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      mem_req_ready = 1'b0;
      #1;
      if ((dut.mem_buffer_valid_q !== 1'b0) ||
          (dut.miq_occupancy_token_mask_w[V11O_TOKEN_BUFFER] !== 1'b0))
        v11o_oracle_fail("buffer-cancel-next-cycle-clear");
      v11o_wait_token_dead(
          V11O_TOKEN_BUFFER, "buffer-cancel-tracker-death");
      $display("[V11O-LEGACY-CANCEL-AUTHORITY-DEATH][PASS] lane=0 token=%0d",
               V11O_TOKEN_BUFFER);
    end
  endtask

  task automatic run_v11o_memory_buffer_token_semantic;
    begin
      if (TB_ENABLE_DUAL_MEM != 0)
        v11o_oracle_fail("legacy-testbench-parameter");
      v11o_transfer_store_buffer();
      v11o_cancel_store_buffer();
      $display("[V11O-MEMORY-BUFFER-TOKEN-MATRIX][PASS] birth_lane0=1 birth_lane1=1 hold_cycles=6 transfer_miq=1 cancel_authority=1 tracker_death=2 product_reachability=external");
      reset_dut();
    end
  endtask
`endif
`ifdef V11N_MEMORY_PENDING_HOLDER_FOCUSED
  task automatic v11n_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11N-MEM-PENDING-HOLDER-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11n_check_tracker_exact;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [1023:0] stage;
    begin
      if ((dut.mem_owner_live_mask_w[token] !== 1'b1) ||
          (dut.mem_owner_kind_table_w[token*2 +: 2] !==
           V11N_ATOMIC_KIND) ||
          (dut.mem_owner_epoch_table_w[token*2 +: 2] !== V11N_EPOCH) ||
          (dut.mem_owner_producer_id_table_w[
              token*PRODUCER_ID_W +: PRODUCER_ID_W] !== producer_id)) begin
        $display("[V11N-TRACKER-DIAG] stage=%0s token=%0d live=%b kind=%h epoch=%h pid=%h expected_pid=%h",
                 stage, token, dut.mem_owner_live_mask_w[token],
                 dut.mem_owner_kind_table_w[token*2 +: 2],
                 dut.mem_owner_epoch_table_w[token*2 +: 2],
                 dut.mem_owner_producer_id_table_w[
                     token*PRODUCER_ID_W +: PRODUCER_ID_W],
                 producer_id);
        v11n_oracle_fail(stage);
      end
    end
  endtask

  task automatic v11n_check_pending_holder;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input write_phase;
    input write_sent;
    input [1023:0] stage;
    begin
      if ((dut.mem_pending_q !== 1'b1) ||
          (dut.mem_amo_q !== 1'b1) ||
          (dut.mem_amo_lr_q !== 1'b0) ||
          (dut.mem_amo_sc_q !== 1'b0) ||
          (dut.mem_producer_id_q !== producer_id) ||
          (dut.mem_rob_idx_q !== producer_id[ROB_INDEX_W-1:0]) ||
          (dut.mem_owner_kind_q !== V11N_ATOMIC_KIND) ||
          (dut.mem_owner_token_q !== token) ||
          (dut.mem_mmu_epoch_q !== V11N_EPOCH) ||
          (dut.mem_amo_write_phase_q !== write_phase) ||
          (dut.mem_amo_write_sent_q !== write_sent) ||
          (dut.mem_amo_tracker_exact_w !== 1'b1) ||
          (dut.mem_amo_tracker_producer_id_w !== producer_id)) begin
        $display("[V11N-PENDING-DIAG] stage=%0s pending=%b amo=%b lr/sc=%b/%b pid=%h expected_pid=%h rob=%h kind=%h token=%0d expected_token=%0d epoch=%h phase/sent=%b/%b tracker=%b tracker_pid=%h",
                 stage, dut.mem_pending_q, dut.mem_amo_q,
                 dut.mem_amo_lr_q, dut.mem_amo_sc_q,
                 dut.mem_producer_id_q, producer_id, dut.mem_rob_idx_q,
                 dut.mem_owner_kind_q, dut.mem_owner_token_q, token,
                 dut.mem_mmu_epoch_q, dut.mem_amo_write_phase_q,
                 dut.mem_amo_write_sent_q, dut.mem_amo_tracker_exact_w,
                 dut.mem_amo_tracker_producer_id_w);
        v11n_oracle_fail(stage);
      end
      v11n_check_tracker_exact(producer_id, token, stage);
    end
  endtask

  task automatic v11n_check_terminal_lane;
    input integer lane;
    input [4:0] token;
    input [1023:0] stage;
    begin
      if ((dut.mem_terminal_ingress_valid_w[lane] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[lane] !== 1'b1) ||
          (dut.mem_terminal_ingress_kind_w[lane*2 +: 2] !==
           V11N_ATOMIC_KIND) ||
          (dut.mem_terminal_ingress_token_w[lane*5 +: 5] !== token) ||
          (dut.mem_terminal_ingress_epoch_w[lane*2 +: 2] !==
           V11N_EPOCH))
        v11n_oracle_fail(stage);
    end
  endtask

  task automatic v11n_wait_token_dead;
    input [4:0] token;
    input [1023:0] stage;
    integer wait_cycle;
    begin
      wait_cycle = 0;
      while (((dut.mem_owner_live_mask_w[token] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[token] === 1'b1)) &&
             (wait_cycle < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((dut.mem_owner_live_mask_w[token] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[token] !== 1'b0))
        v11n_oracle_fail(stage);
    end
  endtask

  task automatic v11n_prime_full_width_identity;
    begin
      run_v8n_prime_producer_generation();
      force dut.u_mem_owner_tracker.next_token_q = V11N_TOKEN;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11N_TOKEN)
        v11n_oracle_fail("token-cursor-prime-force");
      release dut.u_mem_owner_tracker.next_token_q;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11N_TOKEN)
        v11n_oracle_fail("token-cursor-prime-release");
    end
  endtask

  task automatic v11n_seed_amo_read;
    input dispatch_lane1;
    input [PRODUCER_ID_W-1:0] expected_pid;
    integer wait_cycle;
    begin
      reset_dut();
      v11n_prime_full_width_identity();
      commit_ready = 1'b1;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      if (dispatch_lane1) begin
        set_dispatch0(
            V11N_PC0,
            make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                          `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
            5'd0, 5'd0, 5'd22, 64'h66);
        set_dispatch1(
            V11N_PC1, make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
            5'd0, 5'd0, 5'd21, 64'd0);
        dispatch1_inst =
            inst_amo(5'b00000, 5'd0, 5'd0, `FUNCT3_LD, 5'd21);
        #1;
        if ((dispatch0_ready !== 1'b1) ||
            (dispatch1_ready !== 1'b1) ||
            (dispatch0_producer_id !== V11N_PID0) ||
            (dut.dispatch1_producer_id_w !== expected_pid))
          v11n_oracle_fail("dispatch1-amo-identity");
      end else begin
        set_dispatch0(
            V11N_PC0, make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
            5'd0, 5'd0, 5'd20, 64'd0);
        dispatch0_inst =
            inst_amo(5'b00000, 5'd0, 5'd0, `FUNCT3_LD, 5'd20);
        #1;
        if ((dispatch0_ready !== 1'b1) ||
            (dispatch0_producer_id !== expected_pid))
          v11n_oracle_fail("dispatch0-amo-identity");
      end
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      wait_cycle = 0;
      while ((dut.mem_issue_res_valid_q !== 1'b1) &&
             (wait_cycle < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue_res_ctrl_q[`CTRL_AMO_BIT] !== 1'b1) ||
          (dut.mem_issue_res_producer_id_q !== expected_pid) ||
          (dut.mem_issue_res_owner_kind_q !== V11N_ATOMIC_KIND) ||
          (dut.mem_issue_res_owner_token_q !== V11N_TOKEN) ||
          (dut.mem_issue_res_mmu_epoch_q !== V11N_EPOCH) ||
          (dut.mem_issue1_res_ctrl_q[`CTRL_AMO_BIT] !== 1'b0) ||
          (dut.issue1_is_amo_w !== 1'b0))
        v11n_oracle_fail("amo-terminal0-reservation");
      v11n_check_tracker_exact(
          expected_pid, V11N_TOKEN, "reservation-tracker-exact");

      wait_cycle = 0;
      while ((mem_req_valid !== 1'b1) && (wait_cycle < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((mem_req_valid !== 1'b1) ||
          (mem_req_write !== 1'b0) ||
          (mem_req_owner_kind !== V11N_ATOMIC_KIND) ||
          (mem_req_owner_token !== V11N_TOKEN) ||
          (mem_req_mmu_epoch !== V11N_EPOCH) ||
          (dut.issue0_mem_req_valid_w !== 1'b1))
        v11n_oracle_fail("amo-read-request-visible");
      mem_req_ready = 1'b1;
      #1;
      if ((dut.issue0_mem_request_fire_w !== 1'b1) ||
          (dut.issue1_mem_request_fire_w !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b1) ||
          (dut.miq_push_owner_token_w !== V11N_TOKEN))
        v11n_oracle_fail("amo-read-request-fire");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;

      if ((dut.mem_issue_res_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_kind_w !== V11N_ATOMIC_KIND) ||
          (dut.miq_head_owner_token_w !== V11N_TOKEN))
        v11n_oracle_fail("amo-read-next-cycle-miq");
      v11n_check_pending_holder(
          expected_pid, V11N_TOKEN, 1'b0, 1'b0,
          "amo-read-pending-birth");
      if (dispatch_lane1)
        $display("[V11N-DISPATCH1-TO-TERMINAL0][PASS] pid=%0h token=%0d",
                 expected_pid, V11N_TOKEN);
      else
        $display("[V11N-LANE0-FULL-WIDTH-BIRTH][PASS] pid=%0h token=%0d",
                 expected_pid, V11N_TOKEN);
    end
  endtask

  task automatic v11n_enter_write_phase;
    input [PRODUCER_ID_W-1:0] expected_pid;
    input [`XLEN-1:0] read_value;
    begin
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = read_value;
      mem_rsp_error = 1'b0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_amo_read_rsp_w !== 1'b1) ||
          (dut.mem_rsp_final_fire_w !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[0] !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[9] !== 1'b0))
        v11n_oracle_fail("successful-read-nonterminal");
      v11n_check_pending_holder(
          expected_pid, V11N_TOKEN, 1'b0, 1'b0,
          "successful-read-edge-old-holder");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      if (dut.miq_count_w !== 0)
        v11n_oracle_fail("successful-read-miq-pop");
      v11n_check_pending_holder(
          expected_pid, V11N_TOKEN, 1'b1, 1'b0,
          "successful-read-write-phase");
    end
  endtask

  task automatic run_v11n_memory_pending_holder_semantic;
    integer hold_cycle;
    begin
      tb_check32("V11N production dual-memory parameter",
                 TB_ENABLE_DUAL_MEM, 32'd1);

      // A. Lane0 AMO: full-width birth, read hold, phase transition, stalled
      // write grant, write fire, post-write hold, exact final lane0 and death.
      v11n_seed_amo_read(1'b0, V11N_PID0);
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        v11n_check_pending_holder(
            V11N_PID0, V11N_TOKEN, 1'b0, 1'b0, "read-hold");
        `TB_TICK(clk);
        #1;
      end
      v11n_enter_write_phase(V11N_PID0, V11N_READ_VALUE0);

      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        if ((mem_req_valid !== 1'b1) ||
            (mem_req_write !== 1'b1) ||
            (mem_req_owner_kind !== V11N_ATOMIC_KIND) ||
            (mem_req_owner_token !== V11N_TOKEN) ||
            (mem_req_mmu_epoch !== V11N_EPOCH) ||
            (dut.push_amo_write_w !== 1'b0))
          v11n_oracle_fail("write-grant-stall");
        v11n_check_pending_holder(
            V11N_PID0, V11N_TOKEN, 1'b1, 1'b0, "write-grant-hold");
        `TB_TICK(clk);
        #1;
      end

      mem_req_ready = 1'b1;
      #1;
      if ((dut.push_amo_write_w !== 1'b1) ||
          (dut.miq_push_valid_w !== 1'b1) ||
          (dut.miq_push_owner_kind_w !== V11N_ATOMIC_KIND) ||
          (dut.miq_push_owner_token_w !== V11N_TOKEN) ||
          (dut.mem_amo_launch_authorized_w !== 1'b1))
        v11n_oracle_fail("amo-write-fire");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_kind_w !== V11N_ATOMIC_KIND) ||
          (dut.miq_head_owner_token_w !== V11N_TOKEN))
        v11n_oracle_fail("amo-write-next-cycle-miq");
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        v11n_check_pending_holder(
            V11N_PID0, V11N_TOKEN, 1'b1, 1'b1, "post-write-hold");
        `TB_TICK(clk);
        #1;
      end
      $display("[V11N-READ-WRITE-HOLD][PASS] read=2 interphase=2 postwrite=2");

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'd0;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_rsp_final_fire_w !== 1'b1) ||
          (dut.mem_amo_read_rsp_w !== 1'b0) ||
          (dut.mem_completion_producer_id_w !== V11N_PID0) ||
          (dut.mem_terminal_ingress_valid_w[9] !== 1'b0))
        v11n_oracle_fail("amo-final-response");
      v11n_check_terminal_lane(0, V11N_TOKEN, "amo-final-lane0");
      v11n_check_pending_holder(
          V11N_PID0, V11N_TOKEN, 1'b1, 1'b1,
          "amo-final-edge-old-holder");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      if ((dut.mem_pending_q !== 1'b0) || (dut.miq_count_w !== 0))
        v11n_oracle_fail("amo-final-next-cycle-clear");
      v11n_wait_token_dead(V11N_TOKEN, "amo-final-tracker-death");
      $display("[V11N-FINAL-LANE0-DEATH][PASS] pid=%0h token=%0d",
               V11N_PID0, V11N_TOKEN);

      // B. An AMO accepted in dispatch lane1 must be scheduled through the
      // singleton execution terminal0.  Cancel between read and write uses
      // collector lane9 with the same stimulus-owned token.
      v11n_seed_amo_read(1'b1, V11N_PID1);
      v11n_enter_write_phase(V11N_PID1, V11N_READ_VALUE1);
      checkpoint_restore = 1'b1;
      #1;
      if ((dut.checkpoint_restore_apply_w !== 1'b1) ||
          (dut.mem_amo_interphase_cancel_w !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[0] !== 1'b0) ||
          (mem_req_valid !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b0))
        v11n_oracle_fail("amo-interphase-cancel");
      v11n_check_terminal_lane(9, V11N_TOKEN, "amo-interphase-lane9");
      v11n_check_pending_holder(
          V11N_PID1, V11N_TOKEN, 1'b1, 1'b0,
          "amo-interphase-edge-old-holder");
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      if ((dut.mem_pending_q !== 1'b0) || (dut.miq_count_w !== 0))
        v11n_oracle_fail("amo-interphase-next-cycle-clear");
      v11n_wait_token_dead(V11N_TOKEN, "amo-interphase-tracker-death");
      $display("[V11N-INTERPHASE-LANE9-DEATH][PASS] pid=%0h token=%0d",
               V11N_PID1, V11N_TOKEN);

      // C. Read fault is a final lane0 terminal, never a second lane9 event.
      v11n_seed_amo_read(1'b0, V11N_PID0);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'd0;
      mem_rsp_error = 1'b1;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (dut.mem_amo_read_rsp_w !== 1'b0) ||
          (dut.mem_rsp_final_fire_w !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[9] !== 1'b0))
        v11n_oracle_fail("amo-read-fault-final");
      v11n_check_terminal_lane(0, V11N_TOKEN, "amo-read-fault-lane0");
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      #1;
      if ((dut.mem_pending_q !== 1'b0) || (dut.miq_count_w !== 0))
        v11n_oracle_fail("amo-read-fault-next-cycle-clear");
      v11n_wait_token_dead(V11N_TOKEN, "amo-read-fault-tracker-death");
      $display("[V11N-READ-FAULT-LANE0][PASS] token=%0d", V11N_TOKEN);

      $display("[V11N-MEM-PENDING-HOLDER-MATRIX][PASS] birth=2 read_hold=2 phase=2 write_hold=2 final_lane0=1 cancel_lane9=1 read_fault_lane0=1 death=3");
      reset_dut();
    end
  endtask
`endif
`ifdef V11M_MEMORY_RESERVATION_HOLDER_FOCUSED
  task automatic v11m_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11M-RESERVATION-HOLDER-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11m_check_tracker_exact;
    input [4:0] token;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [1023:0] stage;
    begin
      if ((dut.mem_owner_live_mask_w[token] !== 1'b1) ||
          (dut.mem_owner_kind_table_w[token*2 +: 2] !==
           V11M_LOAD_KIND) ||
          (dut.mem_owner_epoch_table_w[token*2 +: 2] !==
           V11M_EPOCH) ||
          (dut.mem_owner_producer_id_table_w[
              token*PRODUCER_ID_W +: PRODUCER_ID_W] !== producer_id)) begin
        $display("[V11M-TRACKER-DIAG] token=%0d live=%b kind=%h epoch=%h pid=%h expected_pid=%h",
                 token,
                 dut.mem_owner_live_mask_w[token],
                 dut.mem_owner_kind_table_w[token*2 +: 2],
                 dut.mem_owner_epoch_table_w[token*2 +: 2],
                 dut.mem_owner_producer_id_table_w[
                     token*PRODUCER_ID_W +: PRODUCER_ID_W],
                 producer_id);
        v11m_oracle_fail(stage);
      end
    end
  endtask

  task automatic v11m_check_reservation0;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] address;
    input [1:0] size;
    input unsigned_load;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue_res_producer_id_q !== producer_id) ||
          (dut.mem_issue_res_owner_token_q !== token) ||
          (dut.mem_issue_res_owner_kind_q !== V11M_LOAD_KIND) ||
          (dut.mem_issue_res_mmu_epoch_q !== V11M_EPOCH) ||
          (dut.mem_issue_res_fault_tval_q !== address) ||
          (dut.mem_issue_res_pc_q !== pc) ||
          (dut.mem_issue_res_imm_q !== address) ||
          (dut.mem_issue_res_pdest_q !== pdest) ||
          (dut.mem_issue_res_ctrl_q[`CTRL_LOAD_BIT] !== 1'b1) ||
          (dut.mem_issue_res_ctrl_q[`CTRL_STORE_BIT] !== 1'b0) ||
          (dut.mem_issue_res_ctrl_q[
              `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] !== size) ||
          (dut.mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] !==
           unsigned_load)) begin
        $display("[V11M-RES0-DIAG] valid=%b pid=%h token=%h kind=%h epoch=%h tval=%h pc=%h imm=%h pdest=%h size=%h unsigned=%b",
                 dut.mem_issue_res_valid_q,
                 dut.mem_issue_res_producer_id_q,
                 dut.mem_issue_res_owner_token_q,
                 dut.mem_issue_res_owner_kind_q,
                 dut.mem_issue_res_mmu_epoch_q,
                 dut.mem_issue_res_fault_tval_q,
                 dut.mem_issue_res_pc_q,
                 dut.mem_issue_res_imm_q,
                 dut.mem_issue_res_pdest_q,
                 dut.mem_issue_res_ctrl_q[
                     `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB],
                 dut.mem_issue_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT]);
        v11m_oracle_fail("reservation0-holder-tuple");
      end
    end
  endtask

  task automatic v11m_check_reservation1;
    input [PRODUCER_ID_W-1:0] producer_id;
    input [4:0] token;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] address;
    input [1:0] size;
    input unsigned_load;
    input [PHY_REG_ADDR_W-1:0] pdest;
    begin
      if ((dut.mem_issue1_res_valid_q !== 1'b1) ||
          (dut.mem_issue1_res_producer_id_q !== producer_id) ||
          (dut.mem_issue1_res_owner_token_q !== token) ||
          (dut.mem_issue1_res_owner_kind_q !== V11M_LOAD_KIND) ||
          (dut.mem_issue1_res_mmu_epoch_q !== V11M_EPOCH) ||
          (dut.mem_issue1_res_fault_tval_q !== address) ||
          (dut.mem_issue1_res_pc_q !== pc) ||
          (dut.mem_issue1_res_imm_q !== address) ||
          (dut.mem_issue1_res_pdest_q !== pdest) ||
          (dut.mem_issue1_res_ctrl_q[`CTRL_LOAD_BIT] !== 1'b1) ||
          (dut.mem_issue1_res_ctrl_q[`CTRL_STORE_BIT] !== 1'b0) ||
          (dut.mem_issue1_res_ctrl_q[
              `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB] !== size) ||
          (dut.mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT] !==
           unsigned_load)) begin
        $display("[V11M-RES1-DIAG] valid=%b pid=%h token=%h kind=%h epoch=%h tval=%h pc=%h imm=%h pdest=%h size=%h unsigned=%b",
                 dut.mem_issue1_res_valid_q,
                 dut.mem_issue1_res_producer_id_q,
                 dut.mem_issue1_res_owner_token_q,
                 dut.mem_issue1_res_owner_kind_q,
                 dut.mem_issue1_res_mmu_epoch_q,
                 dut.mem_issue1_res_fault_tval_q,
                 dut.mem_issue1_res_pc_q,
                 dut.mem_issue1_res_imm_q,
                 dut.mem_issue1_res_pdest_q,
                 dut.mem_issue1_res_ctrl_q[
                     `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB],
                 dut.mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT]);
        v11m_oracle_fail("reservation1-holder-tuple");
      end
    end
  endtask

  task automatic v11m_wait_token_dead;
    input [4:0] token;
    input [1023:0] stage;
    integer wait_cycle;
    begin
      wait_cycle = 0;
      while (((dut.mem_owner_live_mask_w[token] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[token] === 1'b1)) &&
             (wait_cycle < 10)) begin
        `TB_TICK(clk);
        #1;
        wait_cycle = wait_cycle + 1;
      end
      if ((dut.mem_owner_live_mask_w[token] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[token] !== 1'b0))
        v11m_oracle_fail(stage);
    end
  endtask

  task automatic v11m_prime_full_width_identity;
    begin
      // Consume one complete ROB turn through legal ALU dispatch/retirement
      // so the next four ProducerIds carry generation=1.  The reservation
      // test owns these expected identities; it does not sample DUT holder
      // state to construct them.
      run_v8n_prime_producer_generation();

      // The token cursor contract was closed separately.  Seed it at a
      // deterministic reset-domain boundary so this holder test exercises
      // token[4:2] without spending 28 unrelated memory transactions.
      force dut.u_mem_owner_tracker.next_token_q = V11M_TOKEN0;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11M_TOKEN0)
        v11m_oracle_fail("token-cursor-prime-force");
      release dut.u_mem_owner_tracker.next_token_q;
      #1;
      if (dut.u_mem_owner_tracker.next_token_q !== V11M_TOKEN0)
        v11m_oracle_fail("token-cursor-prime-release");
    end
  endtask

  task automatic v11m_seed_first_pair;
    input [`XLEN-1:0] address0;
    input [`XLEN-1:0] address1;
    input [1:0] size0;
    input unsigned0;
    input [1:0] size1;
    input unsigned1;
    input check_credit_barrier;
    begin
      reset_dut();
      v11m_prime_full_width_identity();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      set_dispatch0(V11M_PC0, make_load_ctrl(size0, unsigned0),
                    5'd0, 5'd0, 5'd14, address0);
      set_dispatch1(V11M_PC1, make_load_ctrl(size1, unsigned1),
                    5'd0, 5'd0, 5'd15, address1);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11M_PID0) ||
          (dut.dispatch1_producer_id_w !== V11M_PID1))
        v11m_oracle_fail("dual-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if ((dut.iq_memory_pair_w !== 1'b1) ||
          (dut.mem_issue_pair_capture_candidate_w !== 1'b1) ||
          (dut.mem_issue_res_capture_candidate_w !== 1'b1) ||
          (dut.mem_issue1_res_capture_candidate_w !== 1'b1))
        v11m_oracle_fail("pair-capture-candidate");

      if (check_credit_barrier) begin
        force dut.mem_owner_alloc1_ready_w = 1'b0;
        #1;
        if ((dut.mem_issue_pair_capture_w !== 1'b0) ||
            (dut.mem_issue_res_capture_w !== 1'b0) ||
            (dut.mem_issue1_res_capture_w !== 1'b0) ||
            (dut.iq_issue0_ready_w !== 1'b0))
          v11m_oracle_fail("pair-credit-atomic");
        `TB_TICK(clk);
        #1;
        if ((dut.mem_issue_res_valid_q !== 1'b0) ||
            (dut.mem_issue1_res_valid_q !== 1'b0) ||
            (issue_count !== 2))
          v11m_oracle_fail("pair-credit-edge");
        release dut.mem_owner_alloc1_ready_w;
        #1;
      end

      if ((dut.mem_issue_pair_capture_w !== 1'b1) ||
          (dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_issue1_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11M_TOKEN0) ||
          (dut.mem_owner_alloc1_token_w !== V11M_TOKEN1))
        v11m_oracle_fail("pair-credit-atomic");
      `TB_TICK(clk);
      #1;

      v11m_check_reservation0(
          V11M_PID0, V11M_TOKEN0, V11M_PC0, address0,
          size0, unsigned0, V11M_PDEST0);
      v11m_check_reservation1(
          V11M_PID1, V11M_TOKEN1, V11M_PC1, address1,
          size1, unsigned1, V11M_PDEST1);
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "tracker0-exact-live");
      v11m_check_tracker_exact(
          V11M_TOKEN1, V11M_PID1, "tracker1-exact-live");
      if (issue_count !== 0)
        v11m_oracle_fail("pair-source-iq-not-empty");
    end
  endtask

  task automatic v11m_check_terminal_lane;
    input integer lane;
    input [4:0] token;
    input [1023:0] stage;
    begin
      if ((dut.mem_terminal_ingress_valid_w[lane] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[lane] !== 1'b1) ||
          (dut.mem_terminal_ingress_token_w[lane*5 +: 5] !== token) ||
          (dut.mem_terminal_ingress_kind_w[lane*2 +: 2] !==
           V11M_LOAD_KIND) ||
          (dut.mem_terminal_ingress_epoch_w[lane*2 +: 2] !==
           V11M_EPOCH))
        v11m_oracle_fail(stage);
    end
  endtask

  task automatic v11m_drain_dual_miq_responses;
    input [4:0] token0;
    input [4:0] token1;
    input [PRODUCER_ID_W-1:0] producer0;
    input [PRODUCER_ID_W-1:0] producer1;
    begin
      // Feed final-PA dispositions from the stimulus-owned owner tuple.  The
      // query does not sample MIQ/tracker state to manufacture its identity.
      mem_sq_query_valid = 1'b1;
      mem_sq_query_owner_kind = V11M_LOAD_KIND;
      mem_sq_query_owner_token = token0;
      mem_sq_query_mmu_epoch = V11M_EPOCH;
      mem_sq_query_paddr = V11M_ADDR0;
      mem_sq_query_attr_valid = 1'b1;
      mem_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem_sq_query_wstrb = {`STRB_W{1'b1}};
      mem1_sq_query_valid = 1'b1;
      mem1_sq_query_owner_kind = V11M_LOAD_KIND;
      mem1_sq_query_owner_token = token1;
      mem1_sq_query_mmu_epoch = V11M_EPOCH;
      mem1_sq_query_paddr = V11M_ADDR1;
      mem1_sq_query_attr_valid = 1'b1;
      mem1_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem1_sq_query_wstrb = {`STRB_W{1'b1}};
      #1;
      if ((dut.mem_sq_query_exact_w !== 1'b1) ||
          (dut.mem1_sq_query_exact_w !== 1'b1) ||
          (mem_sq_query_allow !== 1'b1) ||
          (mem1_sq_query_allow !== 1'b1) ||
          (dut.lq_query0_update_w !== 1'b1) ||
          (dut.lq_query1_update_w !== 1'b1))
        v11m_oracle_fail("dual-final-pa-order");
      `TB_TICK(clk);
      mem_sq_query_valid = 1'b0;
      mem_sq_query_owner_kind = 2'b00;
      mem_sq_query_owner_token = 5'b0;
      mem_sq_query_mmu_epoch = 2'b0;
      mem_sq_query_paddr = {`XLEN{1'b0}};
      mem_sq_query_attr_valid = 1'b0;
      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = {`STRB_W{1'b0}};
      mem1_sq_query_valid = 1'b0;
      mem1_sq_query_owner_kind = 2'b00;
      mem1_sq_query_owner_token = 5'b0;
      mem1_sq_query_mmu_epoch = 2'b0;
      mem1_sq_query_paddr = {`XLEN{1'b0}};
      mem1_sq_query_attr_valid = 1'b0;
      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
      #1;

      commit_ready = 1'b1;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1111_2222_3333_4444;
      mem1_rsp_rdata = 64'haaaa_bbbb_cccc_dddd;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (mem1_rsp_ready !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[0] !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[1] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[0] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[1] !== 1'b1) ||
          (dut.mem_terminal_ingress_token_w[0 +: 5] !== token0) ||
          (dut.mem_terminal_ingress_token_w[5 +: 5] !== token1) ||
          (dut.mem_completion_producer_id_w !== producer0) ||
          (dut.mem1_completion_producer_id_w !== producer1)) begin
        $display("[V11M-RESPONSE-DIAG] ready=%b/%b ingress=%b/%b accept=%b/%b token=%h/%h pid=%h/%h expected=%h/%h miq=%0d/%0d",
                 mem_rsp_ready, mem1_rsp_ready,
                 dut.mem_terminal_ingress_valid_w[0],
                 dut.mem_terminal_ingress_valid_w[1],
                 dut.mem_terminal_ingress_accept_w[0],
                 dut.mem_terminal_ingress_accept_w[1],
                 dut.mem_terminal_ingress_token_w[0 +: 5],
                 dut.mem_terminal_ingress_token_w[5 +: 5],
                 dut.mem_completion_producer_id_w,
                 dut.mem1_completion_producer_id_w,
                 producer0, producer1,
                 dut.miq_count_w, dut.miq1_count_w);
        v11m_oracle_fail("dual-response-terminal");
      end
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      #1;
      v11m_wait_token_dead(token0, "response0-tracker-death");
      v11m_wait_token_dead(token1, "response1-tracker-death");
    end
  endtask

  task automatic run_v11m_memory_reservation_holder_semantic;
    integer hold_cycle;
    begin
      tb_check32("V11M production parameter enabled",
                 TB_ENABLE_DUAL_MEM, 32'd1);

      // A/B: pair credit, birth, full tuple hold and asymmetric request
      // transfer.  All expected identities are reset/allocation predictions.
      v11m_seed_first_pair(
          V11M_ADDR0, V11M_ADDR1,
          `MEM_SIZE_DWORD, 1'b1, `MEM_SIZE_WORD, 1'b0, 1'b1);
      $display("[V11M-BIRTH-CREDIT-ATOMIC][PASS] pid=%0h/%0h token=%0d/%0d",
               V11M_PID0, V11M_PID1, V11M_TOKEN0, V11M_TOKEN1);
      $display("[V11M-FULL-WIDTH-IDENTITY][PASS] generation=1 token=28/29");

      for (hold_cycle = 0; hold_cycle < 3;
           hold_cycle = hold_cycle + 1) begin
        v11m_check_reservation0(
            V11M_PID0, V11M_TOKEN0, V11M_PC0, V11M_ADDR0,
            `MEM_SIZE_DWORD, 1'b1, V11M_PDEST0);
        v11m_check_reservation1(
            V11M_PID1, V11M_TOKEN1, V11M_PC1, V11M_ADDR1,
            `MEM_SIZE_WORD, 1'b0, V11M_PDEST1);
        v11m_check_tracker_exact(
            V11M_TOKEN0, V11M_PID0, "hold-tracker0-exact");
        v11m_check_tracker_exact(
            V11M_TOKEN1, V11M_PID1, "hold-tracker1-exact");
        if ((dut.mem_issue_res_consume_fire_w !== 1'b0) ||
            (dut.mem_issue1_res_consume_fire_w !== 1'b0) ||
            (dut.miq_push_valid_w !== 1'b0) ||
            (dut.miq1_push_valid_w !== 1'b0))
          v11m_oracle_fail("ready00-hold-event");
        `TB_TICK(clk);
        #1;
      end
      $display("[V11M-HOLD-TUPLE][PASS] cycles=3");

      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b0;
      #1;
      if ((mem_req_valid !== 1'b1) ||
          (mem_req_owner_token !== V11M_TOKEN0) ||
          (mem_req_owner_kind !== V11M_LOAD_KIND) ||
          (mem_req_mmu_epoch !== V11M_EPOCH) ||
          (mem_req_fault_tval !== V11M_ADDR0) ||
          (mem_req_addr !== V11M_ADDR0) ||
          (dut.mem_issue_res_consume_fire_w !== 1'b1) ||
          (dut.mem_issue1_res_consume_fire_w !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b1) ||
          (dut.miq_push_owner_token_w !== V11M_TOKEN0))
        v11m_oracle_fail("request0-transfer");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 1) ||
          (dut.miq_head_owner_token_w !== V11M_TOKEN0) ||
          (dut.miq_occupancy_token_mask_w !==
           (32'b1 << V11M_TOKEN0)))
        v11m_oracle_fail("request0-next-cycle-miq");
      v11m_check_reservation1(
          V11M_PID1, V11M_TOKEN1, V11M_PC1, V11M_ADDR1,
          `MEM_SIZE_WORD, 1'b0, V11M_PDEST1);
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "request0-tracker-live");
      v11m_check_tracker_exact(
          V11M_TOKEN1, V11M_PID1, "request1-holder-tracker-live");

      mem1_req_ready = 1'b1;
      #1;
      if ((mem1_req_valid !== 1'b1) ||
          (mem1_req_owner_token !== V11M_TOKEN1) ||
          (mem1_req_owner_kind !== V11M_LOAD_KIND) ||
          (mem1_req_mmu_epoch !== V11M_EPOCH) ||
          (mem1_req_fault_tval !== V11M_ADDR1) ||
          (mem1_req_addr !== V11M_ADDR1) ||
          (dut.mem_issue1_res_consume_fire_w !== 1'b1) ||
          (dut.miq1_push_valid_w !== 1'b1) ||
          (dut.miq1_push_owner_token_w !== V11M_TOKEN1))
        v11m_oracle_fail("request1-transfer");
      `TB_TICK(clk);
      mem1_req_ready = 1'b0;
      #1;
      if ((dut.mem_issue1_res_valid_q !== 1'b0) ||
          (dut.miq1_count_w !== 1) ||
          (dut.miq1_head_owner_token_w !== V11M_TOKEN1) ||
          (dut.miq1_occupancy_token_mask_w !==
           (32'b1 << V11M_TOKEN1)))
        v11m_oracle_fail("request1-next-cycle-miq");
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "request0-miq-tracker-live");
      v11m_check_tracker_exact(
          V11M_TOKEN1, V11M_PID1, "request1-miq-tracker-live");
      $display("[V11M-ASYMMETRIC-TRANSFER][PASS] ready=10/01");
      v11m_drain_dual_miq_responses(
          V11M_TOKEN0, V11M_TOKEN1, V11M_PID0, V11M_PID1);

      // Lane0 local exception must transfer only token0 through collector
      // lane6 while the exact lane1 reservation remains resident.
      v11m_seed_first_pair(
          V11M_MISALIGNED0, V11M_ADDR1,
          `MEM_SIZE_DWORD, 1'b1, `MEM_SIZE_WORD, 1'b0, 1'b0);
      mem_translate_active = 1'b1;
      #1;
      if ((dut.mem_issue_res_local_complete_w !== 1'b1) ||
          (dut.mem_issue_res_consume_fire_w !== 1'b1) ||
          (mem_req_valid !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[7] !== 1'b0)) begin
        $display("[V11M-LOCAL0-DIAG] local=%b consume=%b req=%b ex=%b eligible=%b addr=%h lane6=%b/%b lane7=%b",
                 dut.mem_issue_res_local_complete_w,
                 dut.mem_issue_res_consume_fire_w,
                 mem_req_valid,
                 dut.issue0_mem_exception_w,
                 dut.issue0_mem_issue_eligible_w,
                 dut.mem_issue_res_eff_addr_w,
                 dut.mem_terminal_ingress_valid_w[6],
                 dut.mem_terminal_ingress_accept_w[6],
                 dut.mem_terminal_ingress_valid_w[7]);
        v11m_oracle_fail("local0-terminal");
      end
      v11m_check_terminal_lane(6, V11M_TOKEN0, "local0-terminal");
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "local0-edge-old-tracker");
      `TB_TICK(clk);
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b0) ||
          (dut.mem_issue1_res_valid_q !== 1'b1))
        v11m_oracle_fail("local0-next-cycle");
      v11m_wait_token_dead(V11M_TOKEN0, "local0-tracker-death");
      v11m_check_reservation1(
          V11M_PID1, V11M_TOKEN1, V11M_PC1, V11M_ADDR1,
          `MEM_SIZE_WORD, 1'b0, V11M_PDEST1);
      v11m_check_tracker_exact(
          V11M_TOKEN1, V11M_PID1, "local0-survivor-exact");
      $display("[V11M-LOCAL0-LANE6-EXACT][PASS] token=%0d",
               V11M_TOKEN0);

      // Lane1 mirror: lane7 is accepted while lane0 remains exact.
      v11m_seed_first_pair(
          V11M_ADDR0, V11M_MISALIGNED1,
          `MEM_SIZE_DWORD, 1'b1, `MEM_SIZE_DWORD, 1'b0, 1'b0);
      mem_translate_active = 1'b1;
      mem1_translate_active = 1'b1;
      #1;
      if ((dut.mem_issue1_res_local_complete_w !== 1'b1) ||
          (dut.mem_issue1_res_consume_fire_w !== 1'b1) ||
          (mem1_req_valid !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[6] !== 1'b0)) begin
        $display("[V11M-LOCAL1-DIAG] local=%b consume=%b req=%b ex=%b order=%b addr=%h lane6=%b lane7=%b/%b",
                 dut.mem_issue1_res_local_complete_w,
                 dut.mem_issue1_res_consume_fire_w,
                 mem1_req_valid,
                 dut.issue1_mem_exception_w,
                 dut.issue1_mem_order_ready_w,
                 dut.mem_issue1_res_eff_addr_w,
                 dut.mem_terminal_ingress_valid_w[6],
                 dut.mem_terminal_ingress_valid_w[7],
                 dut.mem_terminal_ingress_accept_w[7]);
        v11m_oracle_fail("local1-terminal");
      end
      v11m_check_terminal_lane(7, V11M_TOKEN1, "local1-terminal");
      v11m_check_tracker_exact(
          V11M_TOKEN1, V11M_PID1, "local1-edge-old-tracker");
      `TB_TICK(clk);
      #1;
      if ((dut.mem_issue1_res_valid_q !== 1'b0) ||
          (dut.mem_issue_res_valid_q !== 1'b1))
        v11m_oracle_fail("local1-next-cycle");
      v11m_wait_token_dead(V11M_TOKEN1, "local1-tracker-death");
      v11m_check_reservation0(
          V11M_PID0, V11M_TOKEN0, V11M_PC0, V11M_ADDR0,
          `MEM_SIZE_DWORD, 1'b1, V11M_PDEST0);
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "local1-survivor-exact");
      $display("[V11M-LOCAL1-LANE7-EXACT][PASS] token=%0d",
               V11M_TOKEN1);

      // Selective recovery boundary is producer0.  Lane0 survives; lane1 is
      // younger and terminalizes through lane7.  READY=11 proves request
      // transport remains quiet on the recovery edge.
      v11m_seed_first_pair(
          V11M_ADDR0, V11M_ADDR1,
          `MEM_SIZE_DWORD, 1'b1, `MEM_SIZE_WORD, 1'b0, 1'b0);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = V11M_PID0[ROB_INDEX_W-1:0];
      #1;
      if ((dut.mem_issue_res_kill_w !== 1'b0) ||
          (dut.mem_issue1_res_kill_w !== 1'b1) ||
          (mem_req_valid !== 1'b0) ||
          (mem1_req_valid !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b0) ||
          (dut.miq1_push_valid_w !== 1'b0))
        v11m_oracle_fail("selective-recovery");
      v11m_check_terminal_lane(
          7, V11M_TOKEN1, "selective-recovery-terminal");
      `TB_TICK(clk);
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b1) ||
          (dut.mem_issue1_res_valid_q !== 1'b0))
        v11m_oracle_fail("selective-recovery-next-cycle");
      v11m_wait_token_dead(
          V11M_TOKEN1, "selective-recovery-tracker-death");
      v11m_check_reservation0(
          V11M_PID0, V11M_TOKEN0, V11M_PC0, V11M_ADDR0,
          `MEM_SIZE_DWORD, 1'b1, V11M_PDEST0);
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "selective-survivor-exact");
      flush = 1'b1;
      #1;
      v11m_check_terminal_lane(
          6, V11M_TOKEN0, "selective-survivor-flush");
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      v11m_wait_token_dead(
          V11M_TOKEN0, "selective-survivor-tracker-death");
      $display("[V11M-SELECTIVE-RECOVERY][PASS] survivor=0 killed=1");

      // Global flush overlaps READY=11.  Both pre-request reservations must
      // use lanes6/7 and no request may enter either MIQ.
      v11m_seed_first_pair(
          V11M_ADDR0, V11M_ADDR1,
          `MEM_SIZE_DWORD, 1'b1, `MEM_SIZE_WORD, 1'b0, 1'b0);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      flush = 1'b1;
      #1;
      if ((dut.mem_issue_res_global_cancel_w !== 1'b1) ||
          (dut.mem_issue1_res_global_cancel_w !== 1'b1) ||
          (mem_req_valid !== 1'b0) ||
          (mem1_req_valid !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b0) ||
          (dut.miq1_push_valid_w !== 1'b0))
        v11m_oracle_fail("global-flush-priority");
      v11m_check_terminal_lane(6, V11M_TOKEN0, "global-flush-lane6");
      v11m_check_terminal_lane(7, V11M_TOKEN1, "global-flush-lane7");
      `TB_TICK(clk);
      flush = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      if ((dut.mem_issue_res_valid_q !== 1'b0) ||
          (dut.mem_issue1_res_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 0) ||
          (dut.miq1_count_w !== 0))
        v11m_oracle_fail("global-flush-next-cycle");
      v11m_wait_token_dead(V11M_TOKEN0, "global-flush-token0-death");
      v11m_wait_token_dead(V11M_TOKEN1, "global-flush-token1-death");
      $display("[V11M-GLOBAL-FLUSH][PASS] lanes=6/7");

      // Pair turnover: A/B leave for the two MIQs on the same edge that C/D
      // atomically replace both reservation Qs with tokens2/3.
      v11m_seed_first_pair(
          V11M_ADDR0, V11M_ADDR1,
          `MEM_SIZE_DWORD, 1'b1, `MEM_SIZE_WORD, 1'b0, 1'b0);
      set_dispatch0(V11M_PC2,
                    make_load_ctrl(`MEM_SIZE_HALF, 1'b1),
                    5'd0, 5'd0, 5'd12, V11M_ADDR2);
      set_dispatch1(V11M_PC3,
                    make_load_ctrl(`MEM_SIZE_BYTE, 1'b0),
                    5'd0, 5'd0, 5'd13, V11M_ADDR3);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11M_PID2) ||
          (dut.dispatch1_producer_id_w !== V11M_PID3))
        v11m_oracle_fail("turnover-dispatch-identity");
      `TB_TICK(clk);
      clear_dispatch();
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      if ((dut.iq_memory_pair_peek_valid_w !== 1'b1) ||
          (dut.mem_issue_res_consume_fire_w !== 1'b1) ||
          (dut.mem_issue1_res_consume_fire_w !== 1'b1) ||
          (dut.mem_issue_pair_turnover_capture_w !== 1'b1) ||
          (dut.mem_issue_res_capture_w !== 1'b1) ||
          (dut.mem_issue1_res_capture_w !== 1'b1) ||
          (dut.mem_owner_alloc0_token_w !== V11M_TOKEN2) ||
          (dut.mem_owner_alloc1_token_w !== V11M_TOKEN3) ||
          (mem_req_owner_token !== V11M_TOKEN0) ||
          (mem1_req_owner_token !== V11M_TOKEN1))
        v11m_oracle_fail("pair-turnover");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      v11m_check_reservation0(
          V11M_PID2, V11M_TOKEN2, V11M_PC2, V11M_ADDR2,
          `MEM_SIZE_HALF, 1'b1, V11M_PDEST2);
      v11m_check_reservation1(
          V11M_PID3, V11M_TOKEN3, V11M_PC3, V11M_ADDR3,
          `MEM_SIZE_BYTE, 1'b0, V11M_PDEST3);
      v11m_check_tracker_exact(
          V11M_TOKEN0, V11M_PID0, "turnover-old0-tracker");
      v11m_check_tracker_exact(
          V11M_TOKEN1, V11M_PID1, "turnover-old1-tracker");
      v11m_check_tracker_exact(
          V11M_TOKEN2, V11M_PID2, "turnover-new0-tracker");
      v11m_check_tracker_exact(
          V11M_TOKEN3, V11M_PID3, "turnover-new1-tracker");
      if ((dut.miq_count_w !== 1) ||
          (dut.miq1_count_w !== 1) ||
          (dut.miq_head_owner_token_w !== V11M_TOKEN0) ||
          (dut.miq1_head_owner_token_w !== V11M_TOKEN1) ||
          (issue_count !== 0))
        v11m_oracle_fail("pair-turnover-next-cycle");
      $display("[V11M-PAIR-TURNOVER][PASS] old=%0d/%0d new=%0d/%0d",
               V11M_TOKEN0, V11M_TOKEN1, V11M_TOKEN2, V11M_TOKEN3);
      v11m_drain_dual_miq_responses(
          V11M_TOKEN0, V11M_TOKEN1, V11M_PID0, V11M_PID1);
      flush = 1'b1;
      #1;
      v11m_check_terminal_lane(6, V11M_TOKEN2, "turnover-flush-lane6");
      v11m_check_terminal_lane(7, V11M_TOKEN3, "turnover-flush-lane7");
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      v11m_wait_token_dead(V11M_TOKEN2, "turnover-token2-death");
      v11m_wait_token_dead(V11M_TOKEN3, "turnover-token3-death");

      $display("[V11M-RESERVATION-HOLDER-MATRIX][PASS] birth=2 hold=2 transfer=2 local=2 selective=2 flush=2 turnover=4");
      reset_dut();
    end
  endtask
`endif

`ifdef V11L_MEMORY_RETRY_HOLDER_FOCUSED
  // Reset starts every ROB generation at all-ones and advances it on the
  // accepted allocation.  The first dual dispatch therefore owns full
  // ProducerIds 0 and 1; the memory-owner allocator likewise returns tokens
  // 0 and 1.  These constants are stimulus/spec predictions, not DUT samples.
  localparam [PRODUCER_ID_W-1:0] V11L_PID0 =
      {PRODUCER_ID_W{1'b0}};
  localparam [PRODUCER_ID_W-1:0] V11L_PID1 =
      {{(PRODUCER_ID_W-1){1'b0}}, 1'b1};
  localparam [4:0] V11L_TOKEN0 = 5'd0;
  localparam [4:0] V11L_TOKEN1 = 5'd1;
  localparam [1:0] V11L_LOAD_KIND = 2'b00;
  localparam [1:0] V11L_EPOCH = 2'b00;
  localparam [`XLEN-1:0] V11L_ADDR0 =
      64'h0000_0000_0000_0a00;
  localparam [`XLEN-1:0] V11L_ADDR1 =
      64'h0000_0000_0000_0a08;
  localparam [`XLEN-1:0] V11L_PADDR0 =
      64'h0000_0000_a000_0a00;
  localparam [`XLEN-1:0] V11L_PADDR1 =
      64'h0000_0000_a000_0a08;
`endif
`ifdef V11O_MEMORY_BUFFER_TOKEN_FOCUSED
  // One legal ROB turn makes the next allocations generation=1.  The legacy
  // LR receives token 28 and the younger buffered load receives token 29.
  // These values are stimulus-owned and never sampled from buffer state.
  localparam [PRODUCER_ID_W-1:0] V11O_PID_OLD =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W));
  localparam [PRODUCER_ID_W-1:0] V11O_PID_TRANSFER =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 1);
  localparam [PRODUCER_ID_W-1:0] V11O_PID_BRANCH =
      V11O_PID_TRANSFER;
  localparam [PRODUCER_ID_W-1:0] V11O_PID_CANCEL =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 2);
  localparam [4:0] V11O_TOKEN_OLD = 5'd28;
  localparam [4:0] V11O_TOKEN_BUFFER = 5'd29;
  localparam [1:0] V11O_LOAD_KIND = 2'b00;
  localparam [1:0] V11O_STORE_KIND = 2'b01;
  localparam [1:0] V11O_ATOMIC_KIND = 2'b10;
  localparam [1:0] V11O_EPOCH = 2'b00;
  localparam [`XLEN-1:0] V11O_LR_PC =
      64'h0000_0000_8001_4000;
  localparam [`XLEN-1:0] V11O_BRANCH_PC =
      64'h0000_0000_8001_4004;
  localparam [`XLEN-1:0] V11O_TRANSFER_PC =
      64'h0000_0000_8001_4004;
  localparam [`XLEN-1:0] V11O_CANCEL_PC =
      64'h0000_0000_8001_4008;
  localparam [`XLEN-1:0] V11O_LR_ADDRESS =
      64'h0000_0000_0000_0200;
  localparam [`XLEN-1:0] V11O_TRANSFER_ADDRESS =
      64'h0000_0000_0000_1400;
  localparam [`XLEN-1:0] V11O_CANCEL_ADDRESS =
      64'h0000_0000_0000_1480;
  localparam [`XLEN-1:0] V11O_STORE0_VA =
      64'h0000_0000_4000_4400;
  localparam [`XLEN-1:0] V11O_STORE0_PA =
      64'h0000_0000_8000_4400;
  localparam [`XLEN-1:0] V11O_STORE1_TRANSFER_VA =
      64'h0000_0000_4000_4480;
  localparam [`XLEN-1:0] V11O_STORE1_TRANSFER_PA =
      64'h0000_0000_8000_4480;
  localparam [`XLEN-1:0] V11O_STORE1_CANCEL_VA =
      64'h0000_0000_4000_4500;
`endif
`ifdef V11M_MEMORY_RESERVATION_HOLDER_FOCUSED
  // One legal full ROB turn makes the next four allocations generation=1.
  // The memory-owner cursor is seeded to 28 at a reset-domain boundary, so
  // both full ProducerId generation and token[4:2] are observable.  These
  // identities remain stimulus-owned; no DUT holder state constructs them.
  localparam [PRODUCER_ID_W-1:0] V11M_PID0 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W));
  localparam [PRODUCER_ID_W-1:0] V11M_PID1 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 1);
  localparam [PRODUCER_ID_W-1:0] V11M_PID2 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 2);
  localparam [PRODUCER_ID_W-1:0] V11M_PID3 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 3);
  localparam [4:0] V11M_TOKEN0 = 5'd28;
  localparam [4:0] V11M_TOKEN1 = 5'd29;
  localparam [4:0] V11M_TOKEN2 = 5'd30;
  localparam [4:0] V11M_TOKEN3 = 5'd31;
  localparam [PHY_REG_ADDR_W-1:0] V11M_PDEST0 = 6'd48;
  localparam [PHY_REG_ADDR_W-1:0] V11M_PDEST1 = 6'd49;
  localparam [PHY_REG_ADDR_W-1:0] V11M_PDEST2 = 6'd50;
  localparam [PHY_REG_ADDR_W-1:0] V11M_PDEST3 = 6'd51;
  localparam [1:0] V11M_LOAD_KIND = 2'b00;
  localparam [1:0] V11M_EPOCH = 2'b00;
  localparam [`XLEN-1:0] V11M_PC0 =
      64'h0000_0000_8001_2000;
  localparam [`XLEN-1:0] V11M_PC1 =
      64'h0000_0000_8001_2004;
  localparam [`XLEN-1:0] V11M_PC2 =
      64'h0000_0000_8001_2008;
  localparam [`XLEN-1:0] V11M_PC3 =
      64'h0000_0000_8001_200c;
  localparam [`XLEN-1:0] V11M_ADDR0 =
      64'h0000_0000_0000_0b00;
  localparam [`XLEN-1:0] V11M_ADDR1 =
      64'h0000_0000_0000_0b08;
  localparam [`XLEN-1:0] V11M_ADDR2 =
      64'h0000_0000_0000_0c00;
  localparam [`XLEN-1:0] V11M_ADDR3 =
      64'h0000_0000_0000_0c08;
  localparam [`XLEN-1:0] V11M_MISALIGNED0 =
      64'h0000_0000_0000_0ffd;
  localparam [`XLEN-1:0] V11M_MISALIGNED1 =
      64'h0000_0000_0000_0ffe;
`endif
`ifdef V11N_MEMORY_PENDING_HOLDER_FOCUSED
  // One legal ROB turn makes the next allocations generation=1.  The owner
  // cursor is seeded to token 28 so both identity high-bit domains are
  // checked by a stimulus-owned oracle.
  localparam [PRODUCER_ID_W-1:0] V11N_PID0 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W));
  localparam [PRODUCER_ID_W-1:0] V11N_PID1 =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W) | 1);
  localparam [4:0] V11N_TOKEN = 5'd28;
  localparam [1:0] V11N_ATOMIC_KIND = 2'b10;
  localparam [1:0] V11N_EPOCH = 2'b00;
  localparam [`XLEN-1:0] V11N_PC0 =
      64'h0000_0000_8001_3000;
  localparam [`XLEN-1:0] V11N_PC1 =
      64'h0000_0000_8001_3004;
  localparam [`XLEN-1:0] V11N_READ_VALUE0 =
      64'h1122_3344_5566_7788;
  localparam [`XLEN-1:0] V11N_READ_VALUE1 =
      64'h8877_6655_4433_2211;
`endif
`ifdef V11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED
  // One legal ROB turn makes the next allocation generation=1.  The expected
  // ProducerId and token are stimulus-owned; neither is sampled from the
  // checkpoint holder under test.
  localparam [PRODUCER_ID_W-1:0] V11P_PID =
      ({{PRODUCER_ID_W{1'b0}}} | (1 << ROB_INDEX_W));
  localparam [PRODUCER_ID_W-1:0] V11P_WRONG_GEN_PID =
      V11P_PID ^ (1 << ROB_INDEX_W);
  localparam [4:0] V11P_TOKEN = 5'd28;
  localparam [1:0] V11P_STORE_KIND = 2'b01;
  localparam [1:0] V11P_ATOMIC_KIND = 2'b10;
  localparam [1:0] V11P_EPOCH = 2'b00;
  localparam [`XLEN-1:0] V11P_STORE_PC =
      64'h0000_0000_8001_5000;
  localparam [`XLEN-1:0] V11P_STORE_VA =
      64'h0000_0000_4000_5000;
  localparam [`XLEN-1:0] V11P_STORE_PA =
      64'h0000_0000_8000_5000;
  localparam [`XLEN-1:0] V11P_AMO_PC =
      64'h0000_0000_8001_5080;
  localparam [`XLEN-1:0] V11P_AMO_READ_VALUE =
      64'h0123_4567_89ab_cdef;
`endif

  reg [14:0] v8p_pair_matrix_seen_q;
  reg [PRODUCER_ID_W-1:0] v8p_mem_pid_seen_q [0:7];
  integer v8p_mem_pid_count_q;
  integer v8v_checkpoint_phys_write_count_q;
  integer v8v_checkpoint_b_count_q;
  integer v8v_checkpoint_write_response_count_q;
  integer v8v_checkpoint_store_release_count_q;
  integer v8v_checkpoint_write_retire_count_q;
  integer v8v_checkpoint_apply_count_q;
`ifdef V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
  localparam [`XLEN-1:0] V8X_A_PC = 64'h0000_0000_8000_6f28;
  localparam [`XLEN-1:0] V8X_B_PC = 64'h0000_0000_8000_6f2c;
  localparam [`XLEN-1:0] V8X_A_ADDR = 64'h0000_0000_a000_0700;
  localparam [`XLEN-1:0] V8X_B_ADDR = 64'h0000_0000_a000_0780;
  integer v8x_ar_fire_count_q;
  integer v8x_post_recovery_arvalid_count_q;
  integer v8x_drop0_count_q;
  integer v8x_drop1_count_q;
  integer v8x_miq_pop_count_q;
  integer v8x_terminal_count_q;
  integer v8x_rsp_count_q;
  integer v8x_mem_wb_count_q;
  integer v8x_commit_ab_count_q;
  integer v8x_dcache_fill_count_q;
  integer v8x_lane1_event_count_q;
  integer v8x_ledger_step_q;
  reg v8x_recovery_seen_q;
  reg [1:0] v8x_owner_a_kind_q;
  reg [4:0] v8x_owner_a_token_q;
  reg [1:0] v8x_owner_a_epoch_q;
  reg [`XLEN-1:0] v8x_owner_a_tval_q;
  reg [1:0] v8x_owner_b_kind_q;
  reg [4:0] v8x_owner_b_token_q;
  reg [1:0] v8x_owner_b_epoch_q;
  reg [`XLEN-1:0] v8x_owner_b_tval_q;
`endif

  reg clk;
  reg rst;
  reg flush;
  reg checkpoint_restore;
  wire checkpoint_restore_apply;
  reg pending_system_producer_valid;
  reg [PRODUCER_ID_W-1:0] pending_system_producer_id;

  reg dispatch0_valid;
  wire dispatch0_ready;
  wire [PRODUCER_ID_W-1:0] dispatch0_producer_id;
  reg [`XLEN-1:0] dispatch0_pc;
  reg [`XLEN-1:0] dispatch0_pred_npc;
  reg [`BPU_BHT_INDEX_W-1:0] dispatch0_bht_idx;
  reg dispatch0_pred_taken;
  reg [`INST_W-1:0] dispatch0_inst;
  reg [`CTRL_BUS_W-1:0] dispatch0_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch0_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch0_rd_arch;
  reg [`XLEN-1:0] dispatch0_imm;
  reg dispatch0_is_fp;
  reg dispatch0_fp_load;
  reg dispatch0_fp_store;
  reg dispatch0_fp_double;
  reg dispatch0_fp_gpr_write;
  reg dispatch0_fp_gpr_src;
  reg dispatch0_fp_fs1_en;
  reg dispatch0_fp_fs2_en;
  reg dispatch0_fp_fs3_en;

  reg dispatch1_valid;
  wire dispatch1_ready;
  reg [`XLEN-1:0] dispatch1_pc;
  reg [`XLEN-1:0] dispatch1_pred_npc;
  reg [`BPU_BHT_INDEX_W-1:0] dispatch1_bht_idx;
  reg dispatch1_pred_taken;
  reg [`INST_W-1:0] dispatch1_inst;
  reg [`CTRL_BUS_W-1:0] dispatch1_ctrl;
  reg [`REG_ADDR_W-1:0] dispatch1_rs1_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rs2_arch;
  reg [`REG_ADDR_W-1:0] dispatch1_rd_arch;
  reg [`XLEN-1:0] dispatch1_imm;
  reg dispatch1_is_fp;
  reg dispatch1_fp_load;
  reg dispatch1_fp_store;
  reg dispatch1_fp_double;
  reg dispatch1_fp_gpr_write;
  reg dispatch1_fp_gpr_src;
  reg dispatch1_fp_fs1_en;
  reg dispatch1_fp_fs2_en;
  reg dispatch1_fp_fs3_en;

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
  wire [PRODUCER_ID_W-1:0] commit0_producer_id;

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
  wire control_full_flush_barrier;
  wire [`REDIR_REASON_W-1:0] control_full_flush_reason;
  wire execute0_valid;
  wire execute1_valid;
  wire branch_resolve_valid;
  wire [`XLEN-1:0] branch_resolve_pc;
  wire [`XLEN-1:0] branch_resolve_next_pc;
  wire branch_resolve_misaligned;
  wire [ROB_INDEX_W-1:0] branch_resolve_rob_idx;
  wire branch_resolve_mispredict;
  wire branch_resolve_is_branch;
  wire branch_resolve_taken;
  wire branch_resolve_pred_taken;
  wire [`BPU_BHT_INDEX_W-1:0] branch_resolve_bht_idx;
  wire dispatch_branch_resolve_valid;
  wire [`XLEN-1:0] dispatch_branch_resolve_pc;
  wire [`XLEN-1:0] dispatch_branch_resolve_next_pc;
  wire dispatch_branch_resolve_misaligned;
  wire mem_req_valid;
  wire mem_req_write;
  wire mem_req_probe;
  wire mem_req_pretrans;
  wire mem_req_nokill;
  wire mem_req_attr_valid;
  wire [1:0] mem_req_class;
  wire mem_req_cacheable;
  wire [1:0] mem_req_owner_kind;
  wire [4:0] mem_req_owner_token;
  wire [1:0] mem_req_mmu_epoch;
  wire [`XLEN-1:0] mem_req_fault_tval;
  wire mem_req_device_release;
  wire mem_req_device_cancel;
  wire [`XLEN-1:0] mem_req_addr;
  wire [`XLEN-1:0] mem_req_wdata;
  wire [`STRB_W-1:0] mem_req_wstrb;
  reg mem_req_ready;
  wire mem_rsp_ready;
  reg mem_rsp_valid;
  reg [`XLEN-1:0] mem_rsp_rdata;
  reg mem_rsp_error;
  reg mem_rsp_cacheable;
  reg tb_mem_rsp_attr_valid;
  reg [1:0] tb_mem_rsp_class;
  wire mem_expected_valid;
  wire [1:0] mem_expected_owner_kind;
  wire [4:0] mem_expected_owner_token;
  wire [1:0] mem_expected_mmu_epoch;
  wire mem_expected_tval_valid;
  wire [`XLEN-1:0] mem_expected_fault_tval;
  wire mem_expected_effective_killed;
  wire mem_tracker_expected_valid;
  wire [1:0] mem_tracker_expected_owner_kind;
  wire [4:0] mem_tracker_expected_owner_token;
  wire [1:0] mem_tracker_expected_mmu_epoch;
  wire mem_station_expected_valid;
  wire [1:0] mem_station_expected_owner_kind;
  wire [4:0] mem_station_expected_owner_token;
  wire [1:0] mem_station_expected_mmu_epoch;
  reg mem_translate_active;
  reg mem_owner_query_valid;
  reg [4:0] mem_owner_query_token;
  reg mem_station_query_valid;
  reg [4:0] mem_station_query_token;
  reg tb_mem_drop0_valid;
  reg [1:0] tb_mem_drop0_owner_kind;
  reg [4:0] tb_mem_drop0_owner_token;
  reg [1:0] tb_mem_drop0_mmu_epoch;
  reg [`XLEN-1:0] tb_mem_drop0_fault_tval;
  reg mem_sq_query_valid;
  reg [1:0] mem_sq_query_owner_kind;
  reg [4:0] mem_sq_query_owner_token;
  reg [1:0] mem_sq_query_mmu_epoch;
  reg [`XLEN-1:0] mem_sq_query_paddr;
  reg mem_sq_query_attr_valid;
  reg [1:0] mem_sq_query_class;
  reg [`STRB_W-1:0] mem_sq_query_wstrb;
  wire mem_sq_query_allow;
  wire mem_sq_query_forward;
  wire mem_sq_query_replay;
  wire mem_sq_query_retry_ready;
  wire [`XLEN-1:0] mem_sq_query_forward_data;
  wire mem1_req_valid;
  wire mem1_req_write;
  wire mem1_req_probe;
  wire mem1_req_pretrans;
  wire mem1_req_nokill;
  wire mem1_req_attr_valid;
  wire [1:0] mem1_req_class;
  wire mem1_req_cacheable;
  wire [1:0] mem1_req_owner_kind;
  wire [4:0] mem1_req_owner_token;
  wire [1:0] mem1_req_mmu_epoch;
  wire [`XLEN-1:0] mem1_req_fault_tval;
  wire mem1_req_device_release;
  wire mem1_req_device_cancel;
  wire [`XLEN-1:0] mem1_req_addr;
  wire [`XLEN-1:0] mem1_req_wdata;
  wire [`STRB_W-1:0] mem1_req_wstrb;
  reg mem1_req_ready;
  wire mem1_rsp_ready;
  reg mem1_rsp_valid;
  reg [`XLEN-1:0] mem1_rsp_rdata;
  reg mem1_rsp_error;
  reg mem1_rsp_cacheable;
  reg tb_mem1_rsp_attr_valid;
  reg [1:0] tb_mem1_rsp_class;
  wire mem1_expected_valid;
  wire [1:0] mem1_expected_owner_kind;
  wire [4:0] mem1_expected_owner_token;
  wire [1:0] mem1_expected_mmu_epoch;
  wire mem1_expected_tval_valid;
  wire [`XLEN-1:0] mem1_expected_fault_tval;
  wire mem1_expected_effective_killed;
  wire mem1_tracker_expected_valid;
  wire [1:0] mem1_tracker_expected_owner_kind;
  wire [4:0] mem1_tracker_expected_owner_token;
  wire [1:0] mem1_tracker_expected_mmu_epoch;
  wire mem1_station_expected_valid;
  wire [1:0] mem1_station_expected_owner_kind;
  wire [4:0] mem1_station_expected_owner_token;
  wire [1:0] mem1_station_expected_mmu_epoch;
  reg mem1_translate_active;
  reg mem1_owner_query_valid;
  reg [4:0] mem1_owner_query_token;
  reg mem1_station_query_valid;
  reg [4:0] mem1_station_query_token;
  reg tb_mem1_drop0_valid;
  reg [1:0] tb_mem1_drop0_owner_kind;
  reg [4:0] tb_mem1_drop0_owner_token;
  reg [1:0] tb_mem1_drop0_mmu_epoch;
  reg [`XLEN-1:0] tb_mem1_drop0_fault_tval;
  reg mem1_sq_query_valid;
  reg [1:0] mem1_sq_query_owner_kind;
  reg [4:0] mem1_sq_query_owner_token;
  reg [1:0] mem1_sq_query_mmu_epoch;
  reg [`XLEN-1:0] mem1_sq_query_paddr;
  reg mem1_sq_query_attr_valid;
  reg [1:0] mem1_sq_query_class;
  reg [`STRB_W-1:0] mem1_sq_query_wstrb;
  wire mem1_sq_query_allow;
  wire mem1_sq_query_forward;
  wire mem1_sq_query_replay;
  wire mem1_sq_query_retry_ready;
  wire [`XLEN-1:0] mem1_sq_query_forward_data;
  reg [PHY_REG_ADDR_W-1:0] t3g_load0_pdest;
  reg [PHY_REG_ADDR_W-1:0] t3g_load1_pdest;
  reg [PHY_REG_ADDR_W-1:0] t3g_dependent_pdest;
  // Icarus forbids an automatic task local on the RHS of procedural force.
  // The selective-kill task copies its real branch ROB identity here first.
  reg [ROB_INDEX_W-1:0] t3v_force_branch_rob;
  reg [ROB_INDEX_W-1:0] v8d_force_head_rob;
  reg [ROB_INDEX_W-1:0] v8d_force_boundary_rob;
  reg [ROB_INDEX_W-1:0] v8d_force_completion_rob;
  reg [PRODUCER_ID_W-1:0] v8d_force_ex0_pid;
  reg [PRODUCER_ID_W-1:0] v8d_force_ex1_pid;
  // Icarus requires procedural force RHS storage at module scope.
  reg [PRODUCER_ID_W-1:0] v8f_force_producer_id;
  reg [PRODUCER_ID_W-1:0] v8f_force_lower_pid;
  reg [PRODUCER_ID_W-1:0] v8d_force_longop_pid;
  reg [63:0] v8g_force_kind_table;
  reg [63:0] v8g_force_epoch_table;
  reg [PRODUCER_ID_W-1:0] v8i_force_old_pid;
  reg [PRODUCER_ID_W-1:0] v8i_force_new_pid;
  reg [PRODUCER_ID_W-1:0] v8i_force_stale_pid;
  reg [PRODUCER_ID_W-1:0] v8i_force_live_pid;
  reg [ROB_INDEX_W-1:0] v8i_force_kill_rob;
  reg [ROB_INDEX_W-1:0] v8i_force_head_rob;
  reg [PRODUCER_ID_W-1:0] v8j_force_live_pid;
  reg [PRODUCER_ID_W-1:0] v8j_force_stale_pid;
  reg [PRODUCER_ID_W-1:0] v8j_force_mismatch_pid;
  reg [PRODUCER_ID_W-1:0] v8k_candidate_pid;
  reg [PRODUCER_ID_W-1:0] v8l_force_pid;
  reg [ROB_INDEX_W-1:0] v8t_force_store_rob;
  integer v8n_load_miss_completed;
  integer v8n_mul_completed;
  integer v8n_div_completed;
  integer v8n_load_issue_accepted;
  integer v8n_mul_issue_accepted;
  integer v8n_div_issue_accepted;
  integer v8n_load_dual_issue_cycles;
  integer v8n_mul_dual_issue_cycles;
  integer v8n_div_dual_issue_cycles;
  integer v8n_load_owner_live_completions;
  integer v8n_mul_owner_live_completions;
  integer v8n_div_owner_live_completions;
  integer v8n_rob_valid_peak;
  integer v8n_rob_peak;
  integer v8n_retire_order_violations;

`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
  integer hist_qh_dispatch0_fire_count_q;
  integer hist_qh_dispatch1_fire_count_q;
  integer hist_qh_sq_alloc_fire_count_q;
  integer hist_qh_probe_req_fire_count_q;
  integer hist_qh_probe_rsp_fire_count_q;
  integer hist_qh_c0_commit_count_q;
  integer hist_qh_c0_barrier_count_q;
  integer hist_qh_c1_flush_count_q;
  integer hist_qh_phys_write_fire_count_q;
`endif

  wire unused_mem_ready = mem_rsp_ready;
  wire unused_mem1_ready = mem1_rsp_ready;

`ifdef V11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V11R_INT_LANE1_PACKET_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V11N_MEMORY_PENDING_HOLDER_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V11O_MEMORY_BUFFER_TOKEN_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 0;
`elsif V11M_MEMORY_RESERVATION_HOLDER_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V11L_MEMORY_RETRY_HOLDER_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V9R_SQ_RETRY_C0_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V8S_DUAL_MEMORY_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V8W_MEMORY_RECOVERY_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`elsif V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
  localparam TB_ENABLE_DUAL_MEM = 1;
`else
  localparam TB_ENABLE_DUAL_MEM = 0;
`endif

`include "tests/tb_ooo_int_backend_v8x_bridge.svh"

  OooIntBackend #(
    .ENABLE_DUAL_MEM(TB_ENABLE_DUAL_MEM)
  ) dut (
    .clk(clk),
    .rst(rst),
    .head0_context_permit_i(1'b1),
    .fencei_retire_permit_i(1'b1),
    .head0_retire_candidate_valid_o(),
    .head0_identity_valid_o(),
    .head0_identity_o(),
    .flush_i(flush),
    .checkpoint_capture_i(1'b0),
    .checkpoint_restore_i(checkpoint_restore),
    .checkpoint_quiesce_i(1'b0),
    .checkpoint_restore_apply_o(checkpoint_restore_apply),
    .mem_issue_block_i(1'b0),
    .pending_branch_fast_valid_i(1'b0),
    .pending_branch_fast_pc_i({`XLEN{1'b0}}),
    .pending_system_producer_valid_i(pending_system_producer_valid),
    .pending_system_producer_id_i(pending_system_producer_id),
    .recover_gprs_i({(`XLEN * `REG_NUM){1'b0}}),
    .dispatch0_valid_i(dispatch0_valid),
    .dispatch0_ready_o(dispatch0_ready),
    .dispatch0_producer_id_o(dispatch0_producer_id),
    .dispatch0_pc_i(dispatch0_pc),
    .dispatch0_next_pc_i(dispatch0_pc + 32'd4),
    .dispatch0_pred_npc_i(dispatch0_pred_npc),
    .dispatch0_inst_i(dispatch0_inst),
    .dispatch0_ctrl_i(dispatch0_ctrl),
    .dispatch0_rs1_arch_i(dispatch0_rs1_arch),
    .dispatch0_rs2_arch_i(dispatch0_rs2_arch),
    .dispatch0_rd_arch_i(dispatch0_rd_arch),
    .dispatch0_imm_i(dispatch0_imm),
    .dispatch0_bht_idx_i(dispatch0_bht_idx),
    .dispatch0_pred_taken_i(dispatch0_pred_taken),
    .dispatch0_is_fp_i(dispatch0_is_fp),
    .dispatch0_fp_load_i(dispatch0_fp_load),
    .dispatch0_fp_store_i(dispatch0_fp_store),
    .dispatch0_fp_double_i(dispatch0_fp_double),
    .dispatch0_fp_gpr_write_i(dispatch0_fp_gpr_write),
    .dispatch0_fp_gpr_src_i(dispatch0_fp_gpr_src),
    .dispatch0_fp_fs1_en_i(dispatch0_fp_fs1_en),
    .dispatch0_fp_fs2_en_i(dispatch0_fp_fs2_en),
    .dispatch0_fp_fs3_en_i(dispatch0_fp_fs3_en),
    .dispatch1_is_fp_i(dispatch1_is_fp),
    .dispatch1_fp_load_i(dispatch1_fp_load),
    .dispatch1_fp_store_i(dispatch1_fp_store),
    .dispatch1_fp_double_i(dispatch1_fp_double),
    .dispatch1_fp_gpr_write_i(dispatch1_fp_gpr_write),
    .dispatch1_fp_gpr_src_i(dispatch1_fp_gpr_src),
    .dispatch1_fp_fs1_en_i(dispatch1_fp_fs1_en),
    .dispatch1_fp_fs2_en_i(dispatch1_fp_fs2_en),
    .dispatch1_fp_fs3_en_i(dispatch1_fp_fs3_en),
    .frm_i(3'b000),
    .dispatch1_valid_i(dispatch1_valid),
    .dispatch1_optional_i(1'b0),
    .dispatch1_ready_o(dispatch1_ready),
    .dispatch1_pc_i(dispatch1_pc),
    .dispatch1_next_pc_i(dispatch1_pc + 32'd4),
    .dispatch1_pred_npc_i(dispatch1_pred_npc),
    .dispatch1_inst_i(dispatch1_inst),
    .dispatch1_ctrl_i(dispatch1_ctrl),
    .dispatch1_rs1_arch_i(dispatch1_rs1_arch),
    .dispatch1_rs2_arch_i(dispatch1_rs2_arch),
    .dispatch1_rd_arch_i(dispatch1_rd_arch),
    .dispatch1_imm_i(dispatch1_imm),
    .dispatch1_bht_idx_i(dispatch1_bht_idx),
    .dispatch1_pred_taken_i(dispatch1_pred_taken),
    .mem_req_valid_o(mem_req_valid),
    .mem_req_ready_i(backend_mem_req_ready_i),
    .mem_req_write_o(mem_req_write),
    .mem_req_probe_o(mem_req_probe),
    .mem_req_pretrans_o(mem_req_pretrans),
    .mem_req_nokill_o(mem_req_nokill),
    .mem_req_attr_valid_o(mem_req_attr_valid),
    .mem_req_class_o(mem_req_class),
    .mem_req_cacheable_o(mem_req_cacheable),
    .mem_req_owner_kind_o(mem_req_owner_kind),
    .mem_req_owner_token_o(mem_req_owner_token),
    .mem_req_mmu_epoch_o(mem_req_mmu_epoch),
    .mem_req_fault_tval_o(mem_req_fault_tval),
    .mem_req_device_release_o(mem_req_device_release),
    .mem_req_device_cancel_o(mem_req_device_cancel),
    .mem_req_addr_o(mem_req_addr),
    .mem_req_wdata_o(mem_req_wdata),
    .mem_req_wstrb_o(mem_req_wstrb),
    .mem_rsp_valid_i(backend_mem_rsp_valid_i),
    .mem_rsp_ready_o(mem_rsp_ready),
    .mem_rsp_rdata_i(backend_mem_rsp_rdata_i),
    .mem_rsp_error_i(backend_mem_rsp_error_i),
    .mem_rsp_page_fault_i(backend_mem_rsp_page_fault_i),
    .mem_rsp_attr_valid_i(backend_mem_rsp_attr_valid_i),
    .mem_rsp_class_i(backend_mem_rsp_class_i),
    .mem_rsp_cacheable_i(backend_mem_rsp_cacheable_i),
    // The leaf TB models an in-order bridge by echoing the registered MIQ-head
    // tuple.  Drop/query/residency behavior is covered by the bridge/full-chain
    // focused benches rather than guessed in this functional backend model.
    .mem_rsp_owner_kind_i(backend_mem_rsp_owner_kind_i),
    .mem_rsp_owner_token_i(backend_mem_rsp_owner_token_i),
    .mem_rsp_mmu_epoch_i(backend_mem_rsp_mmu_epoch_i),
    .mem_rsp_fault_tval_i(backend_mem_rsp_fault_tval_i),
    .mem_expected_valid_o(mem_expected_valid),
    .mem_expected_owner_kind_o(mem_expected_owner_kind),
    .mem_expected_owner_token_o(mem_expected_owner_token),
    .mem_expected_mmu_epoch_o(mem_expected_mmu_epoch),
    .mem_expected_tval_valid_o(mem_expected_tval_valid),
    .mem_expected_fault_tval_o(mem_expected_fault_tval),
    .mem_expected_effective_killed_o(mem_expected_effective_killed),
    .mem_owner_query_valid_i(backend_mem_owner_query_valid_i),
    .mem_owner_query_token_i(backend_mem_owner_query_token_i),
    .mem_tracker_expected_valid_o(mem_tracker_expected_valid),
    .mem_tracker_expected_owner_kind_o(mem_tracker_expected_owner_kind),
    .mem_tracker_expected_owner_token_o(mem_tracker_expected_owner_token),
    .mem_tracker_expected_mmu_epoch_o(mem_tracker_expected_mmu_epoch),
    .mem_station_query_valid_i(backend_mem_station_query_valid_i),
    .mem_station_query_token_i(backend_mem_station_query_token_i),
    .mem_station_expected_valid_o(mem_station_expected_valid),
    .mem_station_expected_owner_kind_o(mem_station_expected_owner_kind),
    .mem_station_expected_owner_token_o(mem_station_expected_owner_token),
    .mem_station_expected_mmu_epoch_o(mem_station_expected_mmu_epoch),
    .mem_drop0_valid_i(backend_mem_drop0_valid_i),
    .mem_drop0_owner_kind_i(backend_mem_drop0_owner_kind_i),
    .mem_drop0_owner_token_i(backend_mem_drop0_owner_token_i),
    .mem_drop0_mmu_epoch_i(backend_mem_drop0_mmu_epoch_i),
    .mem_drop0_fault_tval_i(backend_mem_drop0_fault_tval_i),
    .mem_drop1_valid_i(backend_mem_drop1_valid_i),
    .mem_drop1_owner_kind_i(backend_mem_drop1_owner_kind_i),
    .mem_drop1_owner_token_i(backend_mem_drop1_owner_token_i),
    .mem_drop1_mmu_epoch_i(backend_mem_drop1_mmu_epoch_i),
    .mem_drop1_fault_tval_i(backend_mem_drop1_fault_tval_i),
    .mem_bridge_owner_residency_mask_i(
        backend_mem_bridge_owner_residency_mask_i),
    .mem_sq_query_valid_i(backend_mem_sq_query_valid_i),
    .mem_sq_query_owner_kind_i(backend_mem_sq_query_owner_kind_i),
    .mem_sq_query_owner_token_i(backend_mem_sq_query_owner_token_i),
    .mem_sq_query_mmu_epoch_i(backend_mem_sq_query_mmu_epoch_i),
    .mem_sq_query_paddr_i(backend_mem_sq_query_paddr_i),
    .mem_sq_query_attr_valid_i(backend_mem_sq_query_attr_valid_i),
    .mem_sq_query_class_i(backend_mem_sq_query_class_i),
    .mem_sq_query_wstrb_i(backend_mem_sq_query_wstrb_i),
    .mem_sq_query_allow_o(mem_sq_query_allow),
    .mem_sq_query_forward_o(mem_sq_query_forward),
    .mem_sq_query_replay_o(mem_sq_query_replay),
    .mem_sq_query_retry_ready_o(mem_sq_query_retry_ready),
    .mem_sq_query_forward_data_o(mem_sq_query_forward_data),
    .mem_translate_active_i(backend_mem_translate_active_i),
    .mem1_req_valid_o(mem1_req_valid),
    .mem1_req_ready_i(backend_mem1_req_ready_i),
    .mem1_req_write_o(mem1_req_write),
    .mem1_req_probe_o(mem1_req_probe),
    .mem1_req_pretrans_o(mem1_req_pretrans),
    .mem1_req_nokill_o(mem1_req_nokill),
    .mem1_req_attr_valid_o(mem1_req_attr_valid),
    .mem1_req_class_o(mem1_req_class),
    .mem1_req_cacheable_o(mem1_req_cacheable),
    .mem1_req_owner_kind_o(mem1_req_owner_kind),
    .mem1_req_owner_token_o(mem1_req_owner_token),
    .mem1_req_mmu_epoch_o(mem1_req_mmu_epoch),
    .mem1_req_fault_tval_o(mem1_req_fault_tval),
    .mem1_req_device_release_o(mem1_req_device_release),
    .mem1_req_device_cancel_o(mem1_req_device_cancel),
    .mem1_req_addr_o(mem1_req_addr),
    .mem1_req_wdata_o(mem1_req_wdata),
    .mem1_req_wstrb_o(mem1_req_wstrb),
    .mem1_rsp_valid_i(backend_mem1_rsp_valid_i),
    .mem1_rsp_ready_o(mem1_rsp_ready),
    .mem1_rsp_rdata_i(backend_mem1_rsp_rdata_i),
    .mem1_rsp_error_i(backend_mem1_rsp_error_i),
    .mem1_rsp_page_fault_i(backend_mem1_rsp_page_fault_i),
    .mem1_rsp_attr_valid_i(backend_mem1_rsp_attr_valid_i),
    .mem1_rsp_class_i(backend_mem1_rsp_class_i),
    .mem1_rsp_cacheable_i(backend_mem1_rsp_cacheable_i),
    .mem1_rsp_owner_kind_i(backend_mem1_rsp_owner_kind_i),
    .mem1_rsp_owner_token_i(backend_mem1_rsp_owner_token_i),
    .mem1_rsp_mmu_epoch_i(backend_mem1_rsp_mmu_epoch_i),
    .mem1_rsp_fault_tval_i(backend_mem1_rsp_fault_tval_i),
    .mem1_expected_valid_o(mem1_expected_valid),
    .mem1_expected_owner_kind_o(mem1_expected_owner_kind),
    .mem1_expected_owner_token_o(mem1_expected_owner_token),
    .mem1_expected_mmu_epoch_o(mem1_expected_mmu_epoch),
    .mem1_expected_tval_valid_o(mem1_expected_tval_valid),
    .mem1_expected_fault_tval_o(mem1_expected_fault_tval),
    .mem1_expected_effective_killed_o(mem1_expected_effective_killed),
    .mem1_owner_query_valid_i(backend_mem1_owner_query_valid_i),
    .mem1_owner_query_token_i(backend_mem1_owner_query_token_i),
    .mem1_tracker_expected_valid_o(mem1_tracker_expected_valid),
    .mem1_tracker_expected_owner_kind_o(mem1_tracker_expected_owner_kind),
    .mem1_tracker_expected_owner_token_o(mem1_tracker_expected_owner_token),
    .mem1_tracker_expected_mmu_epoch_o(mem1_tracker_expected_mmu_epoch),
    .mem1_station_query_valid_i(backend_mem1_station_query_valid_i),
    .mem1_station_query_token_i(backend_mem1_station_query_token_i),
    .mem1_station_expected_valid_o(mem1_station_expected_valid),
    .mem1_station_expected_owner_kind_o(mem1_station_expected_owner_kind),
    .mem1_station_expected_owner_token_o(mem1_station_expected_owner_token),
    .mem1_station_expected_mmu_epoch_o(mem1_station_expected_mmu_epoch),
    .mem1_drop0_valid_i(backend_mem1_drop0_valid_i),
    .mem1_drop0_owner_kind_i(backend_mem1_drop0_owner_kind_i),
    .mem1_drop0_owner_token_i(backend_mem1_drop0_owner_token_i),
    .mem1_drop0_mmu_epoch_i(backend_mem1_drop0_mmu_epoch_i),
    .mem1_drop0_fault_tval_i(backend_mem1_drop0_fault_tval_i),
    .mem1_drop1_valid_i(backend_mem1_drop1_valid_i),
    .mem1_drop1_owner_kind_i(backend_mem1_drop1_owner_kind_i),
    .mem1_drop1_owner_token_i(backend_mem1_drop1_owner_token_i),
    .mem1_drop1_mmu_epoch_i(backend_mem1_drop1_mmu_epoch_i),
    .mem1_drop1_fault_tval_i(backend_mem1_drop1_fault_tval_i),
    .mem1_bridge_owner_residency_mask_i(
        backend_mem1_bridge_owner_residency_mask_i),
    .mem1_sq_query_valid_i(backend_mem1_sq_query_valid_i),
    .mem1_sq_query_owner_kind_i(backend_mem1_sq_query_owner_kind_i),
    .mem1_sq_query_owner_token_i(backend_mem1_sq_query_owner_token_i),
    .mem1_sq_query_mmu_epoch_i(backend_mem1_sq_query_mmu_epoch_i),
    .mem1_sq_query_paddr_i(backend_mem1_sq_query_paddr_i),
    .mem1_sq_query_attr_valid_i(backend_mem1_sq_query_attr_valid_i),
    .mem1_sq_query_class_i(backend_mem1_sq_query_class_i),
    .mem1_sq_query_wstrb_i(backend_mem1_sq_query_wstrb_i),
    .mem1_sq_query_allow_o(mem1_sq_query_allow),
    .mem1_sq_query_forward_o(mem1_sq_query_forward),
    .mem1_sq_query_replay_o(mem1_sq_query_replay),
    .mem1_sq_query_retry_ready_o(mem1_sq_query_retry_ready),
    .mem1_sq_query_forward_data_o(mem1_sq_query_forward_data),
    .mem1_translate_active_i(backend_mem1_translate_active_i),
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
    .commit0_producer_id_o(commit0_producer_id),
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
    .control_full_flush_barrier_o(control_full_flush_barrier),
    .control_full_flush_reason_o(control_full_flush_reason),
	    .issue_count_o(issue_count),
	    .execute0_valid_o(execute0_valid),
	    .execute1_valid_o(execute1_valid),
	    .branch_resolve_valid_o(branch_resolve_valid),
	    .branch_resolve_pc_o(branch_resolve_pc),
	    .branch_resolve_next_pc_o(branch_resolve_next_pc),
	    .branch_resolve_misaligned_o(branch_resolve_misaligned),
	    .branch_resolve_rob_idx_o(branch_resolve_rob_idx),
	    .branch_resolve_mispredict_o(branch_resolve_mispredict),
	    .branch_resolve_is_branch_o(branch_resolve_is_branch),
	    .branch_resolve_taken_o(branch_resolve_taken),
	    .branch_resolve_pred_taken_o(branch_resolve_pred_taken),
	    .branch_resolve_bht_idx_o(branch_resolve_bht_idx),
	    .dispatch_branch_resolve_valid_o(dispatch_branch_resolve_valid),
	    .dispatch_branch_resolve_pc_o(dispatch_branch_resolve_pc),
	    .dispatch_branch_resolve_next_pc_o(dispatch_branch_resolve_next_pc),
	    .dispatch_branch_resolve_misaligned_o(dispatch_branch_resolve_misaligned)
	  );

  // Focused exactly-once counters for checkpoint recovery across an
  // irrevocable physical store.  reset_dut() establishes a fresh observation
  // window for each delayed-B/same-edge-B scenario.
  always @(posedge clk) begin
    if (rst) begin
      v8v_checkpoint_phys_write_count_q <= 0;
      v8v_checkpoint_b_count_q <= 0;
      v8v_checkpoint_write_response_count_q <= 0;
      v8v_checkpoint_store_release_count_q <= 0;
      v8v_checkpoint_write_retire_count_q <= 0;
      v8v_checkpoint_apply_count_q <= 0;
    end else begin
      if (dut.checkpoint_irrevocable_write_launch_w)
        v8v_checkpoint_phys_write_count_q <=
            v8v_checkpoint_phys_write_count_q + 1;
      if (dut.miq_drain_rsp_fire_w)
        v8v_checkpoint_b_count_q <= v8v_checkpoint_b_count_q + 1;
      if (dut.mem_rsp_final_fire_w &&
          dut.checkpoint_irrevocable_write_q)
        v8v_checkpoint_write_response_count_q <=
            v8v_checkpoint_write_response_count_q + 1;
      if (dut.sq_release_fire_w)
        v8v_checkpoint_store_release_count_q <=
            v8v_checkpoint_store_release_count_q + 1;
      if (dut.checkpoint_irrevocable_write_retire_w)
        v8v_checkpoint_write_retire_count_q <=
            v8v_checkpoint_write_retire_count_q + 1;
      if (checkpoint_restore_apply)
        v8v_checkpoint_apply_count_q <=
            v8v_checkpoint_apply_count_q + 1;
    end
  end

`ifdef V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
  // Per-owner ledger for the real backend+bridge recovery trace.  A bridge
  // drop is an unbackpressured one-cycle terminal; on that same edge the
  // backend must select the exact MIQ head and present the same tuple to
  // collector ingress lane2.  The ledger samples edge-old identities, before
  // the MIQ head advances from A to B.
  always @(posedge clk) begin
    if (rst) begin
      v8x_ar_fire_count_q <= 0;
      v8x_post_recovery_arvalid_count_q <= 0;
      v8x_drop0_count_q <= 0;
      v8x_drop1_count_q <= 0;
      v8x_miq_pop_count_q <= 0;
      v8x_terminal_count_q <= 0;
      v8x_rsp_count_q <= 0;
      v8x_mem_wb_count_q <= 0;
      v8x_commit_ab_count_q <= 0;
      v8x_dcache_fill_count_q <= 0;
      v8x_lane1_event_count_q <= 0;
      v8x_ledger_step_q <= 0;
      v8x_recovery_seen_q <= 1'b0;
    end else begin
      if (v8x_d_axi_arvalid && v8x_d_axi_arready)
        v8x_ar_fire_count_q <= v8x_ar_fire_count_q + 1;
      if (dut.branch_resolve_mispredict_w)
        v8x_recovery_seen_q <= 1'b1;
      if (v8x_recovery_seen_q && v8x_d_axi_arvalid)
        v8x_post_recovery_arvalid_count_q <=
            v8x_post_recovery_arvalid_count_q + 1;
      if (v8x_lane0_drop1_valid || v8x_lane1_drop1_valid)
        v8x_drop1_count_q <= v8x_drop1_count_q + 1;
      if (v8x_lane0_rsp_valid || v8x_lane1_rsp_valid)
        v8x_rsp_count_q <= v8x_rsp_count_q + 1;
      if (dut.mem_wb_fire_w || dut.mem1_wb_fire_w)
        v8x_mem_wb_count_q <= v8x_mem_wb_count_q + 1;
      if ((commit0_valid && ((commit0_pc == V8X_A_PC) ||
                             (commit0_pc == V8X_B_PC))) ||
          (commit1_valid && ((commit1_pc == V8X_A_PC) ||
                             (commit1_pc == V8X_B_PC))))
        v8x_commit_ab_count_q <= v8x_commit_ab_count_q + 1;
      if (v8x_bridge.u_bridge0.dcache_read_fill_valid_w ||
          v8x_bridge.u_bridge1.dcache_read_fill_valid_w)
        v8x_dcache_fill_count_q <= v8x_dcache_fill_count_q + 1;
      if (v8x_lane1_owner_query_valid ||
          v8x_lane1_station_query_valid ||
          v8x_lane1_rsp_valid || v8x_lane1_drop0_valid ||
          v8x_lane1_drop1_valid)
        v8x_lane1_event_count_q <= v8x_lane1_event_count_q + 1;

      if (dut.miq_queue_pop_valid_w) begin
        v8x_miq_pop_count_q <= v8x_miq_pop_count_q + 1;
        if (!v8x_lane0_drop0_valid) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V8X bank0 MIQ pop without bridge drop @%0t",
                   $time);
        end
      end
      if (dut.mem_terminal_ingress_valid_w[2]) begin
        v8x_terminal_count_q <= v8x_terminal_count_q + 1;
        if (!v8x_lane0_drop0_valid) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V8X collector lane2 without bridge drop @%0t",
                   $time);
        end
      end

      if (v8x_lane0_drop0_valid) begin
        v8x_drop0_count_q <= v8x_drop0_count_q + 1;
        if (!dut.miq_queue_pop_valid_w ||
            !dut.mem_terminal_ingress_valid_w[2]) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V8X drop lacks same-edge MIQ pop/terminal step=%0d @%0t",
                   v8x_ledger_step_q, $time);
        end
        if (dut.mem_terminal_ingress_valid_w != 12'b0000_0000_0100) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V8X unexpected concurrent terminal lanes=%b @%0t",
                   dut.mem_terminal_ingress_valid_w, $time);
        end
        if (v8x_ledger_step_q == 0) begin
          if ((v8x_lane0_drop0_owner_kind !== v8x_owner_a_kind_q) ||
              (v8x_lane0_drop0_owner_token !== v8x_owner_a_token_q) ||
              (v8x_lane0_drop0_mmu_epoch !== v8x_owner_a_epoch_q) ||
              (v8x_lane0_drop0_fault_tval !== v8x_owner_a_tval_q) ||
              (dut.miq_head_owner_kind_w !== v8x_owner_a_kind_q) ||
              (dut.miq_head_owner_token_w !== v8x_owner_a_token_q) ||
              (dut.miq_head_mmu_epoch_w !== v8x_owner_a_epoch_q) ||
              (dut.miq_head_fault_tval_w !== v8x_owner_a_tval_q)) begin
            tb_errors = tb_errors + 1;
            $display("[CHECK-FAIL] V8X terminal step0 is not exact owner A @%0t",
                     $time);
          end
        end else if (v8x_ledger_step_q == 1) begin
          if ((v8x_lane0_drop0_owner_kind !== v8x_owner_b_kind_q) ||
              (v8x_lane0_drop0_owner_token !== v8x_owner_b_token_q) ||
              (v8x_lane0_drop0_mmu_epoch !== v8x_owner_b_epoch_q) ||
              (v8x_lane0_drop0_fault_tval !== v8x_owner_b_tval_q) ||
              (dut.miq_head_owner_kind_w !== v8x_owner_b_kind_q) ||
              (dut.miq_head_owner_token_w !== v8x_owner_b_token_q) ||
              (dut.miq_head_mmu_epoch_w !== v8x_owner_b_epoch_q) ||
              (dut.miq_head_fault_tval_w !== v8x_owner_b_tval_q)) begin
            tb_errors = tb_errors + 1;
            $display("[CHECK-FAIL] V8X terminal step1 is not exact owner B @%0t",
                     $time);
          end
        end else begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V8X unexpected extra bridge drop step=%0d @%0t",
                   v8x_ledger_step_q, $time);
        end

        if ((dut.mem_terminal_ingress_kind_w[(2*2)+:2] !==
             v8x_lane0_drop0_owner_kind) ||
            (dut.mem_terminal_ingress_token_w[(2*5)+:5] !==
             v8x_lane0_drop0_owner_token) ||
            (dut.mem_terminal_ingress_epoch_w[(2*2)+:2] !==
             v8x_lane0_drop0_mmu_epoch)) begin
          tb_errors = tb_errors + 1;
          $display("[CHECK-FAIL] V8X bridge drop/collector tuple mismatch @%0t",
                   $time);
        end
        v8x_ledger_step_q <= v8x_ledger_step_q + 1;
      end
    end
  end
`endif

`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
  // Historical queue-head CSR / younger-SQ proof ledger.  Every event is
  // counted directly on its accepting edge; no sticky "seen" state and no
  // duplicate suppression participates in the oracle.
  always @(posedge clk) begin
    if (rst) begin
      hist_qh_dispatch0_fire_count_q <= 0;
      hist_qh_dispatch1_fire_count_q <= 0;
      hist_qh_sq_alloc_fire_count_q <= 0;
      hist_qh_probe_req_fire_count_q <= 0;
      hist_qh_probe_rsp_fire_count_q <= 0;
      hist_qh_c0_commit_count_q <= 0;
      hist_qh_c0_barrier_count_q <= 0;
      hist_qh_c1_flush_count_q <= 0;
      hist_qh_phys_write_fire_count_q <= 0;
    end else begin
      if (dut.dispatch0_fire_w)
        hist_qh_dispatch0_fire_count_q <=
            hist_qh_dispatch0_fire_count_q + 1;
      if (dut.dispatch1_fire_w)
        hist_qh_dispatch1_fire_count_q <=
            hist_qh_dispatch1_fire_count_q + 1;
      if ((dut.sq_alloc0_valid_w && dut.sq_alloc0_ready_w) ||
          (dut.sq_alloc1_valid_w && dut.sq_alloc1_ready_w))
        hist_qh_sq_alloc_fire_count_q <=
            hist_qh_sq_alloc_fire_count_q + 1;
      if (mem_req_valid && mem_req_ready && mem_req_probe)
        hist_qh_probe_req_fire_count_q <=
            hist_qh_probe_req_fire_count_q + 1;
      if (mem_rsp_valid && mem_rsp_ready && dut.sq_fill_valid_w &&
          dut.sq_fill_probe_w)
        hist_qh_probe_rsp_fire_count_q <=
            hist_qh_probe_rsp_fire_count_q + 1;
      if (commit0_valid)
        hist_qh_c0_commit_count_q <= hist_qh_c0_commit_count_q + 1;
      if (control_full_flush_barrier &&
          (control_full_flush_reason == `REDIR_REASON_CSR_COMMIT))
        hist_qh_c0_barrier_count_q <=
            hist_qh_c0_barrier_count_q + 1;
      if (flush)
        hist_qh_c1_flush_count_q <= hist_qh_c1_flush_count_q + 1;
      if (mem_req_valid && mem_req_ready && mem_req_write &&
          !mem_req_probe)
        hist_qh_phys_write_fire_count_q <=
            hist_qh_phys_write_fire_count_q + 1;
    end
  end
`endif

`ifdef S2_G1_RSP_TRACE
  // Optional focused trace.  It is compiled out of the canonical module test
  // and exists only to distinguish a real in-flight response from a stale
  // outer-transport beat before the assert build intentionally terminates.
  always @(posedge clk) begin
    if (!rst && mem_rsp_valid)
      $display("[S2-G1-RSP-TRACE] t=%0t ready=%0b miq_count=%0d head=%0b kind=%0d effective_kill=%0b pop_transport=%0b owner_match=%0b mem_pending=%0b flush=%0b restore=%0b",
               $time, mem_rsp_ready, dut.miq_count_w,
               dut.miq_head_valid_w, dut.miq_head_kind_w,
               dut.miq_head_effective_killed_w,
               dut.miq_pop_transport_w, dut.miq_pop_owner_match_w,
               dut.mem_pending_q, flush, checkpoint_restore);
  end
`endif

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

  function [`CTRL_BUS_W-1:0] make_muldiv_ctrl;
    begin
      make_muldiv_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2,
                                      `ALU_OP_ADD, 1'b1, 1'b1, 1'b1);
      make_muldiv_ctrl[`CTRL_MULDIV_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_fp_arith_ctrl;
    begin
      make_fp_arith_ctrl = {`CTRL_BUS_W{1'b0}};
      make_fp_arith_ctrl[`CTRL_VALID_BIT] = 1'b1;
      make_fp_arith_ctrl[`CTRL_NEED_EXEC_BIT] = 1'b1;
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

  function [`INST_W-1:0] inst_op_fp;
    input [6:0] funct7;
    input [4:0] fs2;
    input [4:0] fs1;
    input [2:0] rm;
    input [4:0] frd;
    begin
      inst_op_fp = {funct7, fs2, fs1, rm, frd, `OPCODE_OP_FP};
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

  task automatic run_v8p_nonmemory_pair;
    input integer matrix_bit;
    input integer older_kind;
    input integer younger_kind;
    reg [`CTRL_BUS_W-1:0] older_ctrl;
    reg [`CTRL_BUS_W-1:0] younger_ctrl;
    reg [`XLEN-1:0] pc0;
    reg [`XLEN-1:0] pc1;
    begin
      reset_dut();
      pc0 = 64'h0000_0000_8000_b000 + (matrix_bit * 16);
      pc1 = pc0 + 64'd4;
      older_ctrl = v8p_ctrl_for_kind(older_kind, `MEM_SIZE_DWORD);
      younger_ctrl = v8p_ctrl_for_kind(younger_kind, `MEM_SIZE_DWORD);
      set_dispatch0(pc0, older_ctrl, 5'd0, 5'd0, 5'd10, 64'd8);
      set_dispatch1(pc1, younger_ctrl, 5'd0, 5'd0, 5'd11, 64'd12);
      dispatch0_pred_npc = ((older_kind == V8P_KIND_BRANCH) ||
                            (older_kind == V8P_KIND_JAL)) ?
                           (pc0 + 64'd8) :
                           (older_kind == V8P_KIND_JALR) ? 64'd8 :
                                                          (pc0 + 64'd4);
      dispatch1_pred_npc = ((younger_kind == V8P_KIND_BRANCH) ||
                            (younger_kind == V8P_KIND_JAL)) ?
                           (pc1 + 64'd12) :
                           (younger_kind == V8P_KIND_JALR) ? 64'd12 :
                                                            (pc1 + 64'd4);
      #1;
      tb_check1("V8P nonmemory dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8P nonmemory dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8P nonmemory terminal0 resident select",
                dut.iq_issue0_valid_w, 1'b1);
      tb_check1("V8P nonmemory terminal1 resident select",
                dut.issue1_valid_w, 1'b1);
      tb_check1("V8P nonmemory fire0 ready", dut.iq_issue0_ready_w, 1'b1);
      tb_check1("V8P nonmemory fire1 ready", dut.issue1_ready_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8P nonmemory accepted coverage",
                v8p_pair_matrix_seen_q[matrix_bit], 1'b1);
      $display("[V8P-PAIR-ACCEPT] bit=%0d older=%0d younger=%0d PASS",
               matrix_bit, older_kind, younger_kind);
    end
  endtask

  task automatic run_v8p_mixed_memory_pair;
    input integer matrix_bit;
    input integer older_kind;
    input integer younger_kind;
    reg [`CTRL_BUS_W-1:0] older_ctrl;
    reg [`CTRL_BUS_W-1:0] younger_ctrl;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      older_ctrl = v8p_ctrl_for_kind(older_kind, `MEM_SIZE_DWORD);
      younger_ctrl = v8p_ctrl_for_kind(younger_kind, `MEM_SIZE_WORD);
      set_dispatch0(64'h0000_0000_8000_b100 + (matrix_bit * 16),
                    older_ctrl, 5'd0, 5'd0,
                    (older_kind == V8P_KIND_LOAD) ? 5'd12 :
                    (older_kind == V8P_KIND_STORE) ? 5'd0 : 5'd10,
                    64'h0000_0000_0000_0800 + (matrix_bit * 64));
      set_dispatch1(64'h0000_0000_8000_b104 + (matrix_bit * 16),
                    younger_ctrl, 5'd0, 5'd0,
                    (younger_kind == V8P_KIND_LOAD) ? 5'd13 :
                    (younger_kind == V8P_KIND_STORE) ? 5'd0 : 5'd11,
                    64'h0000_0000_0000_0c00 + (matrix_bit * 64));
      #1;
      tb_check1("V8P mixed dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8P mixed dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8P mixed terminal0 resident select",
                dut.iq_issue0_valid_w, 1'b1);
      tb_check1("V8P mixed ALU terminal resident select",
                dut.issue1_valid_w, 1'b1);
      tb_check1("V8P mixed fire0 ready", dut.iq_issue0_ready_w, 1'b1);
      tb_check1("V8P mixed fire1 ready", dut.issue1_ready_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8P mixed accepted coverage",
                v8p_pair_matrix_seen_q[matrix_bit], 1'b1);
      tb_check1("V8P mixed memory captured in bank0",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V8P mixed does not allocate bank1",
                dut.mem_issue1_res_valid_q, 1'b0);
      $display("[V8P-PAIR-ACCEPT] bit=%0d older=%0d younger=%0d PASS",
               matrix_bit, older_kind, younger_kind);
    end
  endtask

  task automatic v8p_prime_registers;
    input [`XLEN-1:0] base0;
    input [`XLEN-1:0] base1;
    input [`XLEN-1:0] data0;
    input [`XLEN-1:0] data1;
    begin
      set_dispatch0(64'h0000_0000_8000_b800,
                    v8p_ctrl_for_kind(V8P_KIND_ALU, `MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd1, base0);
      set_dispatch1(64'h0000_0000_8000_b804,
                    v8p_ctrl_for_kind(V8P_KIND_ALU, `MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd2, base1);
      tick_dispatch_to_commit("V8P prime bases", base0, base1);
      set_dispatch0(64'h0000_0000_8000_b808,
                    v8p_ctrl_for_kind(V8P_KIND_ALU, `MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd3, data0);
      set_dispatch1(64'h0000_0000_8000_b80c,
                    v8p_ctrl_for_kind(V8P_KIND_ALU, `MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd4, data1);
      tick_dispatch_to_commit("V8P prime store data", data0, data1);
    end
  endtask

  task automatic v8p_prime_producer_generations;
    integer gen_i;
    begin
      for (gen_i = 0; gen_i < 8; gen_i = gen_i + 1) begin
        set_dispatch0(64'h0000_0000_8000_b700 + (gen_i * 8),
                      v8p_ctrl_for_kind(V8P_KIND_ALU, `MEM_SIZE_DWORD),
                      5'd0, 5'd0, 5'd7, 64'h100 + gen_i);
        set_dispatch1(64'h0000_0000_8000_b704 + (gen_i * 8),
                      v8p_ctrl_for_kind(V8P_KIND_ALU, `MEM_SIZE_DWORD),
                      5'd0, 5'd0, 5'd8, 64'h200 + gen_i);
        tick_dispatch_to_commit("V8P generation ring prime",
                                64'h100 + gen_i, 64'h200 + gen_i);
      end
    end
  endtask

  task automatic run_v8p_memory_pair;
    input integer matrix_bit;
    input integer older_kind;
    input integer younger_kind;
    input [1:0] size0;
    input [1:0] size1;
    input [`XLEN-1:0] base0;
    input [`XLEN-1:0] base1;
    input [`XLEN-1:0] imm0;
    input [`XLEN-1:0] imm1;
    input [`XLEN-1:0] data0;
    input [`XLEN-1:0] data1;
    reg [`CTRL_BUS_W-1:0] ctrl0;
    reg [`CTRL_BUS_W-1:0] ctrl1;
    reg [`XLEN-1:0] expected_addr0;
    reg [`XLEN-1:0] expected_addr1;
    reg [PRODUCER_ID_W-1:0] pid0;
    reg [PRODUCER_ID_W-1:0] pid1;
    integer seen_i;
    integer wait_i;
    begin
      v8p_prime_registers(base0, base1, data0, data1);
      mem_req_ready = 1'b0;
      expected_addr0 = base0 + imm0;
      expected_addr1 = base1 + imm1;
      ctrl0 = v8p_ctrl_for_kind(older_kind, size0);
      ctrl1 = v8p_ctrl_for_kind(younger_kind, size1);
      set_dispatch0(64'h0000_0000_8000_b900 + (matrix_bit * 16),
                    ctrl0, 5'd1, 5'd3,
                    (older_kind == V8P_KIND_LOAD) ? 5'd5 : 5'd0,
                    imm0);
      set_dispatch1(64'h0000_0000_8000_b904 + (matrix_bit * 16),
                    ctrl1, 5'd2, 5'd4,
                    (younger_kind == V8P_KIND_LOAD) ? 5'd6 : 5'd0,
                    imm1);
      #1;
      tb_check1("V8P memory pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8P memory pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8P memory pair terminal0 select", dut.iq_issue0_valid_w,
                1'b1);
`ifdef V8P_MUTATE_SERIALIZE_MEMORY_PAIR
      if (!dut.issue1_valid_w)
        $display("[V8P-MUTATION-ACTIVATED] serialize_memory_pair");
`endif
      tb_check1("V8P memory pair terminal1 select", dut.issue1_valid_w,
                1'b1);
      tb_check1("V8P memory pair capture0 candidate",
                dut.mem_issue_res_capture_candidate_w, 1'b1);
      tb_check1("V8P memory pair capture1 candidate",
                dut.mem_issue1_res_capture_candidate_w, 1'b1);
      tb_check1("V8P memory pair canonical fire0",
                dut.iq_issue0_ready_w, 1'b1);
`ifdef V8P_MUTATE_SPLIT_PAIR_READY
      if (dut.iq_issue0_ready_w && !dut.issue1_ready_w)
        $display("[V8P-MUTATION-ACTIVATED] split_pair_ready");
`endif
      tb_check1("V8P memory pair canonical fire1",
                dut.issue1_ready_w, 1'b1);
      tb_check1("V8P tracker atomic alloc0 fire",
                dut.u_mem_owner_tracker.alloc0_fire_w, 1'b1);
`ifdef V8P_MUTATE_OWNER1_TIEOFF
      if (dut.u_mem_owner_tracker.alloc0_fire_w &&
          !dut.u_mem_owner_tracker.alloc1_fire_w)
        $display("[V8P-MUTATION-ACTIVATED] owner1_tieoff");
`endif
      tb_check1("V8P tracker atomic alloc1 fire",
                dut.u_mem_owner_tracker.alloc1_fire_w, 1'b1);
`ifdef V8P_MUTATE_TOKEN_ALIAS
      if (dut.u_mem_owner_tracker.alloc0_fire_w &&
          dut.u_mem_owner_tracker.alloc1_fire_w &&
          (dut.mem_owner_alloc0_token_w == dut.mem_owner_alloc1_token_w))
        $display("[V8P-MUTATION-ACTIVATED] token_alias");
`endif
      tb_check1("V8P dual tokens differ before capture",
                dut.mem_owner_alloc0_token_w !=
                dut.mem_owner_alloc1_token_w, 1'b1);
      if (older_kind == V8P_KIND_STORE)
        tb_check1("V8P applicable SQ bind0", dut.sq_owner_bind_valid_w,
                  1'b1);
      if (younger_kind == V8P_KIND_STORE)
        tb_check1("V8P applicable SQ bind1", dut.sq_owner_bind1_valid_w,
                  1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8P memory accepted coverage",
                v8p_pair_matrix_seen_q[matrix_bit], 1'b1);
      tb_check1("V8P bank0 next-Q valid", dut.mem_issue_res_valid_q, 1'b1);
`ifdef V8P_MUTATE_BANK1_TIEOFF
      if (dut.mem_issue_res_valid_q && !dut.mem_issue1_res_valid_q)
        $display("[V8P-MUTATION-ACTIVATED] bank1_tieoff");
`endif
      tb_check1("V8P bank1 next-Q valid", dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V8P bank0 tracker live",
                dut.mem_owner_live_mask_w[dut.mem_issue_res_owner_token_q],
                1'b1);
      tb_check1("V8P bank1 tracker live",
                dut.mem_owner_live_mask_w[dut.mem_issue1_res_owner_token_q],
                1'b1);
      tb_check1("V8P captured tokens distinct",
                dut.mem_issue_res_owner_token_q !=
                dut.mem_issue1_res_owner_token_q, 1'b1);
      tb_check64("V8P AGU0 captured address", dut.issue0_mem_addr_w,
                 expected_addr0);
`ifdef V8P_MUTATE_AGU1_BANK0_COPY
      if (dut.issue1_mem_addr_w == dut.issue0_mem_addr_w)
        $display("[V8P-MUTATION-ACTIVATED] agu1_bank0_copy");
`endif
      tb_check64("V8P AGU1 captured address", dut.issue1_mem_addr_w,
                 expected_addr1);
      pid0 = dut.mem_issue_res_producer_id_q;
      pid1 = dut.mem_issue1_res_producer_id_q;
      tb_check1("V8P memory PID0 generation nonzero",
                |pid0[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
`ifdef V8P_MUTATE_PID1_TRUNCATION
      if (!(|pid1[PRODUCER_ID_W-1:ROB_INDEX_W]))
        $display("[V8P-MUTATION-ACTIVATED] pid1_truncation");
`endif
      tb_check1("V8P memory PID1 generation nonzero",
                |pid1[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
      tb_check1("V8P memory PIDs differ", pid0 != pid1, 1'b1);
      for (seen_i = 0; seen_i < v8p_mem_pid_count_q;
           seen_i = seen_i + 1) begin
        if ((v8p_mem_pid_seen_q[seen_i] == pid0) ||
            (v8p_mem_pid_seen_q[seen_i] == pid1)) begin
          $display("[CHECK-FAIL] V8P memory PID reused pid=%h seen=%0d",
                   v8p_mem_pid_seen_q[seen_i], seen_i);
          tb_errors = tb_errors + 1;
        end
      end
      v8p_mem_pid_seen_q[v8p_mem_pid_count_q] = pid0;
      v8p_mem_pid_seen_q[v8p_mem_pid_count_q + 1] = pid1;
      v8p_mem_pid_count_q = v8p_mem_pid_count_q + 2;
      if (older_kind == V8P_KIND_STORE) begin
        tb_check64("V8P bank0 captured store data",
                   dut.mem_issue_res_store_data_q, data0);
        tb_check64("V8P AGU0 store data", dut.issue0_mem_wdata_w, data0);
        tb_check32("V8P AGU0 store strb",
                   {{(32-`STRB_W){1'b0}}, dut.issue0_mem_wstrb_w},
                   {{(32-`STRB_W){1'b0}}, v8p_strb_for_size(size0)});
      end
      if (younger_kind == V8P_KIND_STORE) begin
        tb_check64("V8P bank1 captured store data",
                   dut.mem_issue1_res_store_data_q, data1);
        tb_check64("V8P AGU1 store data", dut.issue1_mem_wdata_w, data1);
        tb_check32("V8P AGU1 store strb",
                   {{(32-`STRB_W){1'b0}}, dut.issue1_mem_wstrb_w},
                   {{(32-`STRB_W){1'b0}}, v8p_strb_for_size(size1)});
      end
      if ((older_kind == V8P_KIND_STORE) &&
          (younger_kind == V8P_KIND_STORE)) begin
`ifdef V8P_MUTATE_SQ_BIND1_LOST
        if (dut.sq_snoop_owner_valid_w[0] &&
            !dut.sq_snoop_owner_valid_w[1])
          $display("[V8P-MUTATION-ACTIVATED] sq_bind1_lost");
`endif
        tb_check32("V8P store-store exact dual SQ owner binds",
                   {30'b0, dut.sq_snoop_owner_valid_w[1:0]}, 32'd3);
        tb_check32("V8P store-store SQ token0",
                   {27'b0, dut.sq_snoop_owner_token_w[4:0]},
                   {27'b0, dut.mem_issue_res_owner_token_q});
`ifdef V8P_MUTATE_SQ_BIND1_CROSS
        if (dut.sq_snoop_owner_valid_w[1] &&
            (dut.sq_snoop_owner_token_w[9:5] ==
             dut.mem_issue_res_owner_token_q))
          $display("[V8P-MUTATION-ACTIVATED] sq_bind1_cross");
`endif
        tb_check32("V8P store-store SQ token1",
                   {27'b0, dut.sq_snoop_owner_token_w[9:5]},
                   {27'b0, dut.mem_issue1_res_owner_token_q});
      end
`ifdef V8P_MUTATE_BANK1_AGE_BYPASS
      if (dut.mem_issue_res_valid_q && dut.mem_issue1_res_consume_fire_w)
        $display("[V8P-MUTATION-ACTIVATED] bank1_age_bypass");
`endif
      tb_check1("V8P bank1 cannot pass edge-old bank0",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      tb_check1("V8P bank1 cannot request past bank0",
                dut.grant_issue1_w, 1'b0);

      force dut.iq_issue0_src1_data_w = 64'hdead_beef_0000_0001;
      force dut.issue1_src1_value_w = 64'hdead_beef_0000_0002;
      force dut.issue0_src2_data_w = 64'hdead_beef_0000_0003;
      force dut.issue1_src2_value_w = 64'hdead_beef_0000_0004;
      #1;
      tb_check64("V8P AGU0 ignores raw source perturbation",
                 dut.issue0_mem_addr_w, expected_addr0);
`ifdef V8P_MUTATE_BANK1_RAW_FALLTHROUGH
      if (dut.issue1_mem_addr_w != expected_addr1)
        $display("[V8P-MUTATION-ACTIVATED] bank1_raw_fallthrough");
`endif
      tb_check64("V8P AGU1 ignores raw source perturbation",
                 dut.issue1_mem_addr_w, expected_addr1);
      release dut.iq_issue0_src1_data_w;
      release dut.issue1_src1_value_w;
      release dut.issue0_src2_data_w;
      release dut.issue1_src2_value_w;

      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      wait_i = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8P cancel drains all owner tokens",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("V8P cancel drains collector",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
`ifdef V8P_MUTATE_BANK1_CANCEL_LEAK
      if (dut.mem_owner_live_count_w != 0)
        $display("[V8P-MUTATION-ACTIVATED] bank1_cancel_leak");
`endif
      tb_check1("V8P cancel clears bank0", dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("V8P cancel clears bank1", dut.mem_issue1_res_valid_q, 1'b0);
      mem_req_ready = 1'b1;
      $display("[V8P-MEMORY-PAIR] bit=%0d pid0=%h pid1=%h addr0=%h addr1=%h PASS",
               matrix_bit, pid0, pid1, expected_addr0, expected_addr1);
    end
  endtask

  // AMO/LR/SC and FP memory share load/store control bits with ordinary
  // integer memory, so each excluded class is made resident next to a plain
  // load in both program orders.  The check is taken at the resident IQ
  // selection edge: upstream dispatch has already accepted both uops, the
  // plain-memory metadata branch is activated for exactly one entry, and no
  // terminal1 owner/bind/reservation may appear.
  task automatic run_v8p_special_memory_exclusion;
    input integer excluded_kind;
    input integer excluded_older;
    reg [`CTRL_BUS_W-1:0] excluded_ctrl;
    reg [`CTRL_BUS_W-1:0] plain_ctrl;
    reg [`XLEN-1:0] older_pc;
    reg [`XLEN-1:0] younger_pc;
    reg excluded_fp_load;
    reg excluded_fp_store;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      older_pc = 64'h0000_0000_8000_b400 +
                 (excluded_kind * 64) + (excluded_older * 8);
      younger_pc = older_pc + 64'd4;
      plain_ctrl = v8p_ctrl_for_kind(V8P_KIND_LOAD, `MEM_SIZE_DWORD);
      excluded_fp_load = 1'b0;
      excluded_fp_store = 1'b0;
      case (excluded_kind)
        V8P_EXCLUDED_LR:
          excluded_ctrl = make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0);
        V8P_EXCLUDED_SC:
          excluded_ctrl = make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1);
        V8P_EXCLUDED_FP_LOAD: begin
          excluded_ctrl = make_load_ctrl(`MEM_SIZE_DWORD, 1'b1);
          excluded_ctrl[`CTRL_RS1_EN_BIT] = 1'b1;
          excluded_fp_load = 1'b1;
        end
        V8P_EXCLUDED_FP_STORE: begin
          excluded_ctrl = make_store_ctrl(`MEM_SIZE_DWORD);
          excluded_ctrl[`CTRL_RS1_EN_BIT] = 1'b1;
          excluded_fp_store = 1'b1;
        end
        default:
          excluded_ctrl = make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0);
      endcase

      if (excluded_older) begin
        set_dispatch0(older_pc, excluded_ctrl, 5'd0, 5'd0,
                      excluded_fp_store ? 5'd0 : 5'd9, 64'h1200);
        set_dispatch1(younger_pc, plain_ctrl, 5'd0, 5'd0,
                      5'd10, 64'h1280);
        if (excluded_kind <= V8P_EXCLUDED_SC)
          dispatch0_inst = inst_amo(
              (excluded_kind == V8P_EXCLUDED_LR) ? 5'b00010 :
              (excluded_kind == V8P_EXCLUDED_SC) ? 5'b00011 : 5'b00000,
              5'd0, 5'd0, 3'b011, 5'd9);
        if (excluded_fp_load) begin
          dispatch0_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd9,
                            `OPCODE_LOAD_FP};
          dispatch0_is_fp = 1'b1;
          dispatch0_fp_load = 1'b1;
          dispatch0_fp_double = 1'b1;
        end
        if (excluded_fp_store) begin
          dispatch0_inst = {7'd0, 5'd0, 5'd0, 3'b011, 5'd0,
                            `OPCODE_STORE_FP};
          dispatch0_is_fp = 1'b1;
          dispatch0_fp_store = 1'b1;
          dispatch0_fp_double = 1'b1;
          dispatch0_fp_fs2_en = 1'b1;
        end
      end else begin
        set_dispatch0(older_pc, plain_ctrl, 5'd0, 5'd0,
                      5'd10, 64'h1280);
        set_dispatch1(younger_pc, excluded_ctrl, 5'd0, 5'd0,
                      excluded_fp_store ? 5'd0 : 5'd9, 64'h1200);
        if (excluded_kind <= V8P_EXCLUDED_SC)
          dispatch1_inst = inst_amo(
              (excluded_kind == V8P_EXCLUDED_LR) ? 5'b00010 :
              (excluded_kind == V8P_EXCLUDED_SC) ? 5'b00011 : 5'b00000,
              5'd0, 5'd0, 3'b011, 5'd9);
        if (excluded_fp_load) begin
          dispatch1_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd9,
                            `OPCODE_LOAD_FP};
          dispatch1_is_fp = 1'b1;
          dispatch1_fp_load = 1'b1;
          dispatch1_fp_double = 1'b1;
        end
        if (excluded_fp_store) begin
          dispatch1_inst = {7'd0, 5'd0, 5'd0, 3'b011, 5'd0,
                            `OPCODE_STORE_FP};
          dispatch1_is_fp = 1'b1;
          dispatch1_fp_store = 1'b1;
          dispatch1_fp_double = 1'b1;
          dispatch1_fp_fs2_en = 1'b1;
        end
      end
      #1;
      tb_check1("V8P excluded pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8P excluded pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("V8P excluded pair both resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("V8P excluded pair older selected on terminal0",
                dut.iq_issue0_valid_w &&
                (dut.iq_issue0_pc_w == older_pc), 1'b1);
      tb_check1("V8P excluded metadata activates one plain entry",
                dut.u_dispatch_backend.u_issue_queue.
                    plain_memory_terminal_capable_q[excluded_older ? 1 : 0],
                1'b1);
      tb_check1("V8P excluded metadata rejects special entry",
                dut.u_dispatch_backend.u_issue_queue.
                    plain_memory_terminal_capable_q[excluded_older ? 0 : 1],
                1'b0);
      tb_check1("V8P excluded pair is not a plain memory pair",
                dut.iq_memory_pair_w, 1'b0);
`ifdef V8P_MUTATE_SPECIAL_MISADMISSION
      if (dut.issue1_valid_w)
        $display("[V8P-MUTATION-ACTIVATED] special_misadmission");
`endif
      tb_check1("V8P excluded class cannot select terminal1",
                dut.issue1_valid_w, 1'b0);
      tb_check1("V8P excluded class cannot request bank1 capture",
                dut.mem_issue1_res_capture_candidate_w, 1'b0);
      tb_check1("V8P excluded class cannot birth owner1",
                dut.u_mem_owner_tracker.alloc1_fire_w, 1'b0);
      tb_check1("V8P excluded class cannot bind SQ owner1",
                dut.sq_owner_bind1_valid_w, 1'b0);
      tb_check1("V8P terminal0 exclusion case remains live",
                dut.mem_issue_res_capture_candidate_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8P excluded class leaves bank1 empty",
                dut.mem_issue1_res_valid_q, 1'b0);
      tb_check1("V8P terminal0 captured the older memory",
                dut.mem_issue_res_valid_q, 1'b1);
      $display("[V8P-SPECIAL-MEMORY-EXCLUSION] kind=%0d older=%0d resident=2 terminal1=0 PASS",
               excluded_kind, excluded_older);
    end
  endtask

  task automatic run_v8p_pair_matrix_contract;
    begin
      run_v8p_nonmemory_pair(0, V8P_KIND_ALU, V8P_KIND_ALU);
      run_v8p_nonmemory_pair(1, V8P_KIND_ALU, V8P_KIND_BRANCH);
      run_v8p_nonmemory_pair(2, V8P_KIND_BRANCH, V8P_KIND_ALU);
      run_v8p_nonmemory_pair(3, V8P_KIND_ALU, V8P_KIND_JAL);
      run_v8p_nonmemory_pair(4, V8P_KIND_JAL, V8P_KIND_ALU);
      run_v8p_nonmemory_pair(5, V8P_KIND_ALU, V8P_KIND_JALR);
      run_v8p_nonmemory_pair(6, V8P_KIND_JALR, V8P_KIND_ALU);
      run_v8p_mixed_memory_pair(7, V8P_KIND_ALU, V8P_KIND_LOAD);
      run_v8p_mixed_memory_pair(8, V8P_KIND_LOAD, V8P_KIND_ALU);
      run_v8p_mixed_memory_pair(9, V8P_KIND_ALU, V8P_KIND_STORE);
      run_v8p_mixed_memory_pair(10, V8P_KIND_STORE, V8P_KIND_ALU);

      run_v8p_special_memory_exclusion(V8P_EXCLUDED_AMO, 1'b0);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_AMO, 1'b1);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_LR, 1'b0);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_LR, 1'b1);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_SC, 1'b0);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_SC, 1'b1);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_FP_LOAD, 1'b0);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_FP_LOAD, 1'b1);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_FP_STORE, 1'b0);
      run_v8p_special_memory_exclusion(V8P_EXCLUDED_FP_STORE, 1'b1);

      reset_dut();
      v8p_mem_pid_count_q = 0;
      v8p_prime_producer_generations();
      run_v8p_memory_pair(
          11, V8P_KIND_LOAD, V8P_KIND_LOAD,
          `MEM_SIZE_WORD, `MEM_SIZE_DWORD,
          64'h0000_0000_0001_0000, 64'h0000_0000_0002_0000,
          64'h0000_0000_0000_0040, 64'h0000_0000_0000_0080,
          64'h1111_1111_1111_1111, 64'h2222_2222_2222_2222);
      run_v8p_memory_pair(
          12, V8P_KIND_LOAD, V8P_KIND_STORE,
          `MEM_SIZE_HALF, `MEM_SIZE_WORD,
          64'h0000_0000_0003_0000, 64'h0000_0000_0004_0000,
          64'h0000_0000_0000_0020, 64'h0000_0000_0000_0060,
          64'h3333_3333_3333_3333, 64'h4444_4444_4444_4444);
      run_v8p_memory_pair(
          13, V8P_KIND_STORE, V8P_KIND_LOAD,
          `MEM_SIZE_DWORD, `MEM_SIZE_BYTE,
          64'h0000_0000_0005_0000, 64'h0000_0000_0006_0000,
          64'h0000_0000_0000_0100, 64'h0000_0000_0000_0030,
          64'h5555_5555_5555_5555, 64'h6666_6666_6666_6666);
      run_v8p_memory_pair(
          14, V8P_KIND_STORE, V8P_KIND_STORE,
          `MEM_SIZE_BYTE, `MEM_SIZE_HALF,
          64'h0000_0000_0007_0000, 64'h0000_0000_0008_0000,
          64'h0000_0000_0000_0010, 64'h0000_0000_0000_0050,
          64'h7777_7777_7777_7777, 64'h8888_8888_8888_8888);

      tb_check32("V8P eight distinct memory PIDs recorded",
                 v8p_mem_pid_count_q, 32'd8);
      tb_check32("V8P all 15 pair-matrix entries accepted",
                 {17'b0, v8p_pair_matrix_seen_q}, 32'h0000_7fff);
      $display("PAIR_MATRIX alu_alu=1");
      $display("PAIR_MATRIX alu_branch=1");
      $display("PAIR_MATRIX branch_alu=1");
      $display("PAIR_MATRIX alu_jal=1");
      $display("PAIR_MATRIX jal_alu=1");
      $display("PAIR_MATRIX alu_jalr=1");
      $display("PAIR_MATRIX jalr_alu=1");
      $display("PAIR_MATRIX alu_load=1");
      $display("PAIR_MATRIX load_alu=1");
      $display("PAIR_MATRIX alu_store=1");
      $display("PAIR_MATRIX store_alu=1");
      $display("PAIR_MATRIX load_load=1");
      $display("PAIR_MATRIX load_store=1");
      $display("PAIR_MATRIX store_load=1");
      $display("PAIR_MATRIX store_store=1");
`ifdef V8P_MODE_ASSERT
      $display("[V8P-PAIR-METRICS] mode=assert pair_fires=15 memory_pair_fires=4 full_pids=8 nonzero_generation_pids=8 dual_reservations=4 distinct_token_pairs=4 dual_agu_matches=8 store_store_exact_binds=2 special_exclusions=10 raw_fallthrough_violations=0 bank1_age_bypass_violations=0 owner_ghosts=0");
`else
      $display("[V8P-PAIR-METRICS] mode=release pair_fires=15 memory_pair_fires=4 full_pids=8 nonzero_generation_pids=8 dual_reservations=4 distinct_token_pairs=4 dual_agu_matches=8 store_store_exact_binds=2 special_exclusions=10 raw_fallthrough_violations=0 bank1_age_bypass_violations=0 owner_ghosts=0");
`endif
      $display("[V8P-PAIR-MATRIX] mask=%h memory_pids=%0d PASS",
               v8p_pair_matrix_seen_q, v8p_mem_pid_count_q);
    end
  endtask

  // Directly construct the full-FIFO state that launch credit makes
  // unreachable in production, then exercise the defensive same-slot
  // pop+push branch.  The new token's PID and kill-derived tombstone must win
  // over both the edge-old token's kill update and its simultaneous pop.
  task run_v8i_fifo_same_slot_case;
    input [PRODUCER_ID_W-1:0] old_pid;
    input [PRODUCER_ID_W-1:0] new_pid;
    input [ROB_INDEX_W-1:0] kill_rob;
    input expected_new_killed;
    integer slot;
    begin
      reset_dut();
      v8i_force_old_pid = old_pid;
      v8i_force_new_pid = new_pid;
      v8i_force_kill_rob = kill_rob;
      v8i_force_head_rob = {ROB_INDEX_W{1'b0}};

      dut.u_fp_backend.df_head_q = {3{1'b0}};
      dut.u_fp_backend.df_tail_q = {3{1'b0}};
      dut.u_fp_backend.done_fifo_count_q = 4'd8;
      for (slot = 0; slot < 8; slot = slot + 1) begin
        dut.u_fp_backend.df_valid_q[slot] = 1'b1;
        dut.u_fp_backend.df_producer_id_q[slot] = slot + 8;
        dut.u_fp_backend.df_killed_q[slot] = 1'b0;
        dut.u_fp_backend.df_pdest_q[slot] = slot + 1;
        dut.u_fp_backend.df_rd_en_q[slot] = 1'b0;
        dut.u_fp_backend.df_value_q[slot] = slot;
        dut.u_fp_backend.df_fflags_q[slot] = 5'b00000;
      end
      dut.u_fp_backend.df_producer_id_q[0] = v8i_force_old_pid;

      force dut.u_fp_backend.df_push_w = 1'b1;
      force dut.u_fp_backend.done_in_producer_id_w = v8i_force_new_pid;
      force dut.u_fp_backend.done_in_pdest_w = 6'd47;
      force dut.u_fp_backend.done_in_rd_en_w = 1'b0;
      force dut.u_fp_backend.done_in_value_w = 64'hfeed_face_cafe_beef;
      force dut.u_fp_backend.done_in_fflags_w = 5'b10101;
      force dut.u_fp_backend.fpwb_ready_i = 1'b1;
      force dut.u_fp_backend.kill_valid_i = 1'b1;
      force dut.u_fp_backend.kill_rob_idx_i = v8i_force_kill_rob;
      force dut.u_fp_backend.rob_head_idx_i = v8i_force_head_rob;
      #1;
      tb_check1("V8I full replacement has simultaneous pop",
                dut.u_fp_backend.df_pop_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8I full replacement count stays eight",
                 {28'b0, dut.u_fp_backend.done_fifo_count_q}, 32'd8);
      tb_check1("V8I full replacement keeps new valid",
                dut.u_fp_backend.df_valid_q[0], 1'b1);
      tb_check32("V8I full replacement installs new PID",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.u_fp_backend.df_producer_id_q[0]},
                 {{(32-PRODUCER_ID_W){1'b0}}, v8i_force_new_pid});
      tb_check1("V8I full replacement tombstone belongs to new PID",
                dut.u_fp_backend.df_killed_q[0], expected_new_killed);
      tb_check32("V8I full replacement advances head",
                 {29'b0, dut.u_fp_backend.df_head_q}, 32'd1);
      tb_check32("V8I full replacement advances tail",
                 {29'b0, dut.u_fp_backend.df_tail_q}, 32'd1);

      release dut.u_fp_backend.df_push_w;
      release dut.u_fp_backend.done_in_producer_id_w;
      release dut.u_fp_backend.done_in_pdest_w;
      release dut.u_fp_backend.done_in_rd_en_w;
      release dut.u_fp_backend.done_in_value_w;
      release dut.u_fp_backend.done_in_fflags_w;
      release dut.u_fp_backend.fpwb_ready_i;
      release dut.u_fp_backend.kill_valid_i;
      release dut.u_fp_backend.kill_rob_idx_i;
      release dut.u_fp_backend.rob_head_idx_i;
      // One additional edge lets the push-survival assertion consume its
      // captured expectation before reset clears the artificial full state.
      `TB_TICK(clk);
      #1;
      reset_dut();
    end
  endtask

  task run_v8i_generation_separated_transport;
    begin
      reset_dut();
      v8i_force_stale_pid = 3;
      v8i_force_live_pid = (1 << ROB_INDEX_W) | 3;
      tb_check32("V8I stale/live use the same raw ROB index",
                 {{(32-ROB_INDEX_W){1'b0}},
                  v8i_force_stale_pid[ROB_INDEX_W-1:0]},
                 {{(32-ROB_INDEX_W){1'b0}},
                  v8i_force_live_pid[ROB_INDEX_W-1:0]});
      tb_check1("V8I stale/live generations differ",
                v8i_force_stale_pid != v8i_force_live_pid, 1'b1);

      force dut.fp_completion_pending_mask_w =
          ({{((1 << PRODUCER_ID_W)-1){1'b0}}, 1'b1} <<
           v8i_force_stale_pid);
      force dut.fpwb_valid_w = 1'b1;
      force dut.fpwb_producer_id_w = v8i_force_stale_pid;
      force dut.fp_formal_completion_rob_open_w = 1'b0;

      // The stale formal token consumes one raw route, but a live newer
      // generation on the same raw index still completes through EX0.
      force dut.ex0_pre_auth_valid_w = 1'b1;
      force dut.ex0_producer_open_w = 1'b1;
      force dut.ex0_producer_id_q = v8i_force_live_pid;
      #1;
      tb_check1("V8I stale formal still obtains raw route",
                dut.fpwb_ready_w, 1'b1);
      tb_check1("V8I stale formal has no actual claim",
                dut.fpwb_actual_claim_w, 1'b0);
      tb_check1("V8I newer generation EX0 remains actual",
                dut.ex0_wb_valid_w, 1'b1);
      release dut.ex0_pre_auth_valid_w;
      release dut.ex0_producer_open_w;
      release dut.ex0_producer_id_q;

      // The same stale raw formal route also cannot suppress an independent
      // FP result for Q={g+1,i}; full-PID pending lookup must distinguish it.
      force dut.u_fp_backend.arith_out_valid_w = 1'b1;
      force dut.u_fp_backend.arith_out_producer_id_w = v8i_force_live_pid;
      force dut.u_fp_backend.arith_out_rob_w =
          v8i_force_live_pid[ROB_INDEX_W-1:0];
      force dut.u_fp_backend.arith_out_pdest_w = 6'd51;
      force dut.u_fp_backend.arith_out_value_w = 64'h4004_0000_0000_0000;
      force dut.u_fp_backend.arith_out_fflags_w = 5'b00000;
      force dut.fp_result_completion_rob_open_w = 1'b1;
      #1;
      tb_check1("V8I newer generation is not stale pending-owned",
                dut.fp_result_pending_owned_w, 1'b0);
      tb_check1("V8I newer generation FP result remains authorized",
                dut.fp_result_authorized_w, 1'b1);
      tb_check1("V8I newer generation FP result wakes destination",
                dut.fp_wake0_valid_w, 1'b1);
      tb_check1("V8I newer generation FP result pushes its own token",
                dut.u_fp_backend.df_push_w, 1'b1);

      release dut.u_fp_backend.arith_out_valid_w;
      release dut.u_fp_backend.arith_out_producer_id_w;
      release dut.u_fp_backend.arith_out_rob_w;
      release dut.u_fp_backend.arith_out_pdest_w;
      release dut.u_fp_backend.arith_out_value_w;
      release dut.u_fp_backend.arith_out_fflags_w;
      release dut.fp_result_completion_rob_open_w;
      release dut.fp_completion_pending_mask_w;
      release dut.fpwb_valid_w;
      release dut.fpwb_producer_id_w;
      release dut.fp_formal_completion_rob_open_w;
      #1;
      $display("[V8I-FP-GENERATION-TRANSPORT] stale formal/raw-index reuse isolation PASS");
      reset_dut();
    end
  endtask

  task automatic tb_check_fp_issue_packet;
    input [1023:0] what;
    input [FP_ISSUE_PACKET_W-1:0] got;
    input [FP_ISSUE_PACKET_W-1:0] exp;
    begin
      if (got !== exp) begin
        tb_errors = tb_errors + 1;
        $display("[CHECK-FAIL] %0s got=0x%0h expected=0x%0h",
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

  function [`CTRL_BUS_W-1:0] make_jal_ctrl;
    begin
      make_jal_ctrl = make_alu_ctrl(`OP1_SEL_PC, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b0);
      make_jal_ctrl[`CTRL_JAL_BIT] = 1'b1;
    end
  endfunction

  function [`CTRL_BUS_W-1:0] make_jalr_ctrl;
    begin
      make_jalr_ctrl = make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                     `ALU_OP_ADD, 1'b1, 1'b0, 1'b0);
      make_jalr_ctrl[`CTRL_JALR_BIT] = 1'b1;
    end
  endfunction

  function integer v8p_kind_of_ctrl;
    input [`CTRL_BUS_W-1:0] ctrl;
    begin
      if (ctrl[`CTRL_BRANCH_BIT])
        v8p_kind_of_ctrl = V8P_KIND_BRANCH;
      else if (ctrl[`CTRL_JAL_BIT])
        v8p_kind_of_ctrl = V8P_KIND_JAL;
      else if (ctrl[`CTRL_JALR_BIT])
        v8p_kind_of_ctrl = V8P_KIND_JALR;
      else if (ctrl[`CTRL_LOAD_BIT])
        v8p_kind_of_ctrl = V8P_KIND_LOAD;
      else if (ctrl[`CTRL_STORE_BIT])
        v8p_kind_of_ctrl = V8P_KIND_STORE;
      else
        v8p_kind_of_ctrl = V8P_KIND_ALU;
    end
  endfunction

  function integer v8p_pair_index;
    input integer older_kind;
    input integer younger_kind;
    begin
      v8p_pair_index = -1;
      if ((older_kind == V8P_KIND_ALU) &&
          (younger_kind == V8P_KIND_ALU)) v8p_pair_index = 0;
      else if ((older_kind == V8P_KIND_ALU) &&
               (younger_kind == V8P_KIND_BRANCH)) v8p_pair_index = 1;
      else if ((older_kind == V8P_KIND_BRANCH) &&
               (younger_kind == V8P_KIND_ALU)) v8p_pair_index = 2;
      else if ((older_kind == V8P_KIND_ALU) &&
               (younger_kind == V8P_KIND_JAL)) v8p_pair_index = 3;
      else if ((older_kind == V8P_KIND_JAL) &&
               (younger_kind == V8P_KIND_ALU)) v8p_pair_index = 4;
      else if ((older_kind == V8P_KIND_ALU) &&
               (younger_kind == V8P_KIND_JALR)) v8p_pair_index = 5;
      else if ((older_kind == V8P_KIND_JALR) &&
               (younger_kind == V8P_KIND_ALU)) v8p_pair_index = 6;
      else if ((older_kind == V8P_KIND_ALU) &&
               (younger_kind == V8P_KIND_LOAD)) v8p_pair_index = 7;
      else if ((older_kind == V8P_KIND_LOAD) &&
               (younger_kind == V8P_KIND_ALU)) v8p_pair_index = 8;
      else if ((older_kind == V8P_KIND_ALU) &&
               (younger_kind == V8P_KIND_STORE)) v8p_pair_index = 9;
      else if ((older_kind == V8P_KIND_STORE) &&
               (younger_kind == V8P_KIND_ALU)) v8p_pair_index = 10;
      else if ((older_kind == V8P_KIND_LOAD) &&
               (younger_kind == V8P_KIND_LOAD)) v8p_pair_index = 11;
      else if ((older_kind == V8P_KIND_LOAD) &&
               (younger_kind == V8P_KIND_STORE)) v8p_pair_index = 12;
      else if ((older_kind == V8P_KIND_STORE) &&
               (younger_kind == V8P_KIND_LOAD)) v8p_pair_index = 13;
      else if ((older_kind == V8P_KIND_STORE) &&
               (younger_kind == V8P_KIND_STORE)) v8p_pair_index = 14;
    end
  endfunction

  initial begin : v8p_scoreboard_init
    v8p_pair_matrix_seen_q = 15'b0;
    v8p_mem_pid_count_q = 0;
  end

  always @(posedge clk) begin : v8p_accepted_pair_monitor
    integer terminal0_kind;
    integer terminal1_kind;
    integer older_kind;
    integer younger_kind;
    integer pair_index;
    if (!rst && dut.iq_issue0_valid_w && dut.iq_issue0_ready_w &&
        dut.issue1_valid_w && dut.issue1_ready_w) begin
      terminal0_kind = v8p_kind_of_ctrl(dut.iq_issue0_ctrl_w);
      terminal1_kind = v8p_kind_of_ctrl(dut.issue1_ctrl_w);
      older_kind = dut.iq_issue_pair_swapped_w ? terminal1_kind :
                                                     terminal0_kind;
      younger_kind = dut.iq_issue_pair_swapped_w ? terminal0_kind :
                                                       terminal1_kind;
      pair_index = v8p_pair_index(older_kind, younger_kind);
      if (pair_index >= 0)
        v8p_pair_matrix_seen_q[pair_index] <= 1'b1;
    end
  end

  function [`CTRL_BUS_W-1:0] v8p_ctrl_for_kind;
    input integer kind;
    input [1:0] mem_size;
    reg [`CTRL_BUS_W-1:0] ctrl;
    begin
      case (kind)
        V8P_KIND_BRANCH: ctrl = make_branch_ctrl(`CMP_OP_EQ);
        V8P_KIND_JAL: ctrl = make_jal_ctrl();
        V8P_KIND_JALR: ctrl = make_jalr_ctrl();
        V8P_KIND_LOAD: begin
          ctrl = make_load_ctrl(mem_size, 1'b1);
          ctrl[`CTRL_RS1_EN_BIT] = 1'b1;
        end
        V8P_KIND_STORE: begin
          ctrl = make_store_ctrl(mem_size);
          ctrl[`CTRL_RS1_EN_BIT] = 1'b1;
          ctrl[`CTRL_RS2_EN_BIT] = 1'b1;
        end
        default: ctrl = make_alu_ctrl(
            `OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
            1'b0, 1'b0, 1'b1);
      endcase
      v8p_ctrl_for_kind = ctrl;
    end
  endfunction

  function [`STRB_W-1:0] v8p_strb_for_size;
    input [1:0] mem_size;
    begin
      case (mem_size)
        `MEM_SIZE_BYTE: v8p_strb_for_size = 8'h01;
        `MEM_SIZE_HALF: v8p_strb_for_size = 8'h03;
        `MEM_SIZE_WORD: v8p_strb_for_size = 8'h0f;
        default: v8p_strb_for_size = 8'hff;
      endcase
    end
  endfunction

  task automatic clear_dispatch;
    begin
      flush = 1'b0;
      checkpoint_restore = 1'b0;
      pending_system_producer_valid = 1'b0;
      pending_system_producer_id = {PRODUCER_ID_W{1'b0}};
      dispatch0_valid = 1'b0;
      dispatch0_pc = 32'h0;
      dispatch0_pred_npc = {`XLEN{1'b0}};
      dispatch0_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      dispatch0_pred_taken = 1'b0;
      dispatch0_inst = 32'h0;
      dispatch0_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch0_rs1_arch = 5'd0;
      dispatch0_rs2_arch = 5'd0;
      dispatch0_rd_arch = 5'd0;
      dispatch0_imm = 32'h0;
      dispatch0_is_fp = 1'b0;
      dispatch0_fp_load = 1'b0;
      dispatch0_fp_store = 1'b0;
      dispatch0_fp_double = 1'b0;
      dispatch0_fp_gpr_write = 1'b0;
      dispatch0_fp_gpr_src = 1'b0;
      dispatch0_fp_fs1_en = 1'b0;
      dispatch0_fp_fs2_en = 1'b0;
      dispatch0_fp_fs3_en = 1'b0;
      dispatch1_valid = 1'b0;
      dispatch1_pc = 32'h0;
      dispatch1_pred_npc = {`XLEN{1'b0}};
      dispatch1_bht_idx = {`BPU_BHT_INDEX_W{1'b0}};
      dispatch1_pred_taken = 1'b0;
      dispatch1_inst = 32'h0;
      dispatch1_ctrl = {`CTRL_BUS_W{1'b0}};
      dispatch1_rs1_arch = 5'd0;
      dispatch1_rs2_arch = 5'd0;
      dispatch1_rd_arch = 5'd0;
      dispatch1_imm = 32'h0;
      dispatch1_is_fp = 1'b0;
      dispatch1_fp_load = 1'b0;
      dispatch1_fp_store = 1'b0;
      dispatch1_fp_double = 1'b0;
      dispatch1_fp_gpr_write = 1'b0;
      dispatch1_fp_gpr_src = 1'b0;
      dispatch1_fp_fs1_en = 1'b0;
      dispatch1_fp_fs2_en = 1'b0;
      dispatch1_fp_fs3_en = 1'b0;
    end
  endtask

  task automatic reset_dut;
    begin
	      clk = 1'b0;
	      rst = 1'b1;
	      commit_ready = 1'b1;
	      mem_req_ready = 1'b1;
	      mem_rsp_valid = 1'b0;
	      mem_rsp_rdata = {`XLEN{1'b0}};
	      mem_rsp_error = 1'b0;
	      mem_rsp_cacheable = 1'b1;
	      tb_mem_rsp_attr_valid = 1'b1;
	      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
	      mem_translate_active = 1'b0;
	      mem_owner_query_valid = 1'b0;
	      mem_owner_query_token = 5'b0;
	      mem_station_query_valid = 1'b0;
	      mem_station_query_token = 5'b0;
	      tb_mem_drop0_valid = 1'b0;
	      tb_mem_drop0_owner_kind = 2'b11;
	      tb_mem_drop0_owner_token = 5'b0;
	      tb_mem_drop0_mmu_epoch = 2'b0;
	      tb_mem_drop0_fault_tval = {`XLEN{1'b0}};
	      mem_sq_query_valid = 1'b0;
	      mem_sq_query_owner_kind = 2'b00;
	      mem_sq_query_owner_token = 5'b0;
	      mem_sq_query_mmu_epoch = 2'b0;
	      mem_sq_query_paddr = {`XLEN{1'b0}};
	      mem_sq_query_attr_valid = 1'b0;
	      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
	      mem_sq_query_wstrb = {`STRB_W{1'b0}};
	      mem1_req_ready = 1'b1;
	      mem1_rsp_valid = 1'b0;
	      mem1_rsp_rdata = {`XLEN{1'b0}};
	      mem1_rsp_error = 1'b0;
	      mem1_rsp_cacheable = 1'b1;
	      tb_mem1_rsp_attr_valid = 1'b1;
	      tb_mem1_rsp_class = `OOO_MEM_CLASS_CACHED;
	      mem1_translate_active = 1'b0;
	      mem1_owner_query_valid = 1'b0;
	      mem1_owner_query_token = 5'b0;
	      mem1_station_query_valid = 1'b0;
	      mem1_station_query_token = 5'b0;
	      tb_mem1_drop0_valid = 1'b0;
	      tb_mem1_drop0_owner_kind = 2'b11;
	      tb_mem1_drop0_owner_token = 5'b0;
	      tb_mem1_drop0_mmu_epoch = 2'b0;
	      tb_mem1_drop0_fault_tval = {`XLEN{1'b0}};
	      mem1_sq_query_valid = 1'b0;
	      mem1_sq_query_owner_kind = 2'b00;
	      mem1_sq_query_owner_token = 5'b0;
	      mem1_sq_query_mmu_epoch = 2'b0;
	      mem1_sq_query_paddr = {`XLEN{1'b0}};
	      mem1_sq_query_attr_valid = 1'b0;
	      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
	      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
`ifdef V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
          v8x_d_axi_arready = 1'b0;
          v8x_d_axi_rvalid = 1'b0;
          v8x_d_axi_rdata = {`XLEN{1'b0}};
          v8x_d_axi_rresp = 2'b00;
          v8x_d_axi_awready = 1'b0;
          v8x_d_axi_wready = 1'b0;
          v8x_d_axi_bvalid = 1'b0;
          v8x_d_axi_bresp = 2'b00;
`endif
	      clear_dispatch();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  // Record the final-PA StoreQueue disposition for the current ordinary-load
  // MIQ head(s).  Canonical dual-memory mode keeps a load response closed
  // until the shared retire-resident LQ has observed this exact physical
  // address/class/byte-mask tuple and an SQ allow/forward disposition.
  task automatic v8v_record_load_head_order;
    input [1023:0] label;
    input bank0_valid;
    input [`XLEN-1:0] bank0_paddr;
    input bank1_valid;
    input [`XLEN-1:0] bank1_paddr;
    begin
      mem_sq_query_valid = bank0_valid;
      mem_sq_query_owner_kind = bank0_valid ?
          dut.miq_head_owner_kind_w : 2'b00;
      mem_sq_query_owner_token = bank0_valid ?
          dut.miq_head_owner_token_w : 5'b0;
      mem_sq_query_mmu_epoch = bank0_valid ?
          dut.miq_head_mmu_epoch_w : 2'b0;
      mem_sq_query_paddr = bank0_valid ? bank0_paddr : {`XLEN{1'b0}};
      mem_sq_query_attr_valid = bank0_valid;
      mem_sq_query_class = bank0_valid ?
          `OOO_MEM_CLASS_CACHED : `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = bank0_valid ?
          {`STRB_W{1'b1}} : {`STRB_W{1'b0}};

      mem1_sq_query_valid = bank1_valid;
      mem1_sq_query_owner_kind = bank1_valid ?
          dut.miq1_head_owner_kind_w : 2'b00;
      mem1_sq_query_owner_token = bank1_valid ?
          dut.miq1_head_owner_token_w : 5'b0;
      mem1_sq_query_mmu_epoch = bank1_valid ?
          dut.miq1_head_mmu_epoch_w : 2'b0;
      mem1_sq_query_paddr = bank1_valid ? bank1_paddr : {`XLEN{1'b0}};
      mem1_sq_query_attr_valid = bank1_valid;
      mem1_sq_query_class = bank1_valid ?
          `OOO_MEM_CLASS_CACHED : `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = bank1_valid ?
          {`STRB_W{1'b1}} : {`STRB_W{1'b0}};
      #1;

      if (bank0_valid) begin
        tb_check1({label, " bank0 final-PA identity exact"},
                  dut.mem_sq_query_exact_w, 1'b1);
        tb_check1({label, " bank0 SQ nonalias allow"},
                  mem_sq_query_allow, 1'b1);
        tb_check1({label, " bank0 no forward"},
                  mem_sq_query_forward, 1'b0);
        tb_check1({label, " bank0 no replay"},
                  mem_sq_query_replay, 1'b0);
        tb_check1({label, " bank0 LQ disposition update"},
                  dut.lq_query0_update_w, 1'b1);
      end
      if (bank1_valid) begin
        tb_check1({label, " bank1 final-PA identity exact"},
                  dut.mem1_sq_query_exact_w, 1'b1);
        tb_check1({label, " bank1 SQ nonalias allow"},
                  mem1_sq_query_allow, 1'b1);
        tb_check1({label, " bank1 no forward"},
                  mem1_sq_query_forward, 1'b0);
        tb_check1({label, " bank1 no replay"},
                  mem1_sq_query_replay, 1'b0);
        tb_check1({label, " bank1 LQ disposition update"},
                  dut.lq_query1_update_w, 1'b1);
      end

      `TB_TICK(clk);
      mem_sq_query_valid = 1'b0;
      mem_sq_query_owner_kind = 2'b00;
      mem_sq_query_owner_token = 5'b0;
      mem_sq_query_mmu_epoch = 2'b0;
      mem_sq_query_paddr = {`XLEN{1'b0}};
      mem_sq_query_attr_valid = 1'b0;
      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = {`STRB_W{1'b0}};
      mem1_sq_query_valid = 1'b0;
      mem1_sq_query_owner_kind = 2'b00;
      mem1_sq_query_owner_token = 5'b0;
      mem1_sq_query_mmu_epoch = 2'b0;
      mem1_sq_query_paddr = {`XLEN{1'b0}};
      mem1_sq_query_attr_valid = 1'b0;
      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
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
      dispatch0_inst = ctrl[`CTRL_STORE_BIT] ? 32'h0000_3023 : pc;
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
      dispatch1_inst = ctrl[`CTRL_STORE_BIT] ? 32'h0000_3023 : pc;
      dispatch1_ctrl = ctrl;
      dispatch1_rs1_arch = rs1;
      dispatch1_rs2_arch = rs2;
      dispatch1_rd_arch = rd;
      dispatch1_imm = imm;
    end
  endtask

  task automatic set_fp_binary0;
    input [`XLEN-1:0] pc;
    input [6:0] funct7;
    input [4:0] fs2;
    input [4:0] fs1;
    input [4:0] frd;
    input fp_double;
    begin
      set_dispatch0(pc, make_fp_arith_ctrl(), 5'd0, 5'd0, frd, 64'd0);
      dispatch0_inst = inst_op_fp(funct7, fs2, fs1, 3'b000, frd);
      dispatch0_is_fp = 1'b1;
      dispatch0_fp_load = 1'b0;
      dispatch0_fp_store = 1'b0;
      dispatch0_fp_double = fp_double;
      dispatch0_fp_gpr_write = 1'b0;
      dispatch0_fp_gpr_src = 1'b0;
      dispatch0_fp_fs1_en = 1'b1;
      dispatch0_fp_fs2_en = 1'b1;
      dispatch0_fp_fs3_en = 1'b0;
    end
  endtask

  task automatic set_fp_binary1;
    input [`XLEN-1:0] pc;
    input [6:0] funct7;
    input [4:0] fs2;
    input [4:0] fs1;
    input [4:0] frd;
    input fp_double;
    begin
      set_dispatch1(pc, make_fp_arith_ctrl(), 5'd0, 5'd0, frd, 64'd0);
      dispatch1_inst = inst_op_fp(funct7, fs2, fs1, 3'b000, frd);
      dispatch1_is_fp = 1'b1;
      dispatch1_fp_load = 1'b0;
      dispatch1_fp_store = 1'b0;
      dispatch1_fp_double = fp_double;
      dispatch1_fp_gpr_write = 1'b0;
      dispatch1_fp_gpr_src = 1'b0;
      dispatch1_fp_fs1_en = 1'b1;
      dispatch1_fp_fs2_en = 1'b1;
      dispatch1_fp_fs3_en = 1'b0;
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
      tb_check64({label, " request addr"}, mem_req_addr, exp_addr);
      if (!mem_req_pretrans) begin
        tb_check1({label, " ordinary request has no typed attr"},
                  mem_req_attr_valid, 1'b0);
        tb_check32({label, " ordinary request class is RSVD poison"},
                   {30'b0, mem_req_class},
                   {30'b0, `OOO_MEM_CLASS_RSVD});
      end
      if (check_wdata) begin
        tb_check64({label, " request wdata"}, mem_req_wdata, exp_wdata);
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
      // T3W：response/formal-WB 拍只把完成态写入 ROB；architectural
      // commit 必须等下一拍从 ROB Q 发出，不能重新引入 WB-to-head bypass。
      tb_check1({label, " no commit on response/formal-WB"},
                commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      tb_check1({label, " commit valid from ROB Q"},
                commit0_valid, exp_commit);
      if (exp_commit) begin
        tb_check1({label, " commit rd en from ROB Q"},
                  commit0_rd_en, exp_rd_en);
        if (check_data)
          tb_check64({label, " commit data from ROB Q"},
                     commit0_data, exp_data);
        `TB_TICK(clk);
        #1;
        tb_check1({label, " commit exactly once"}, commit0_valid, 1'b0);
      end
    end
  endtask

  // T4N helper.  Caller has already accepted the speculative probe request.
  // Probe success only fills SQ; the later pretranslated write and its B
  // response are the physical request and precise ROB terminal respectively.
  task automatic complete_sq_store_after_probe;
    input [1023:0] label;
    input [`XLEN-1:0] store_va;
    input [`XLEN-1:0] store_pa;
    input probe_cacheable;
    input b_error;
    integer wait_cycles;
    begin
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = store_pa;
      mem_rsp_error = 1'b0;
      mem_rsp_cacheable = probe_cacheable;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = probe_cacheable ? `OOO_MEM_CLASS_CACHED :
                                           `OOO_MEM_CLASS_NC;
      #1;
      tb_check1({label, " probe response ready"}, mem_rsp_ready, 1'b1);
      tb_check1({label, " probe success has no formal WB"},
                dut.mem_wb_fire_w, 1'b0);
      tb_check1({label, " probe success has no commit"}, commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      wait_cycles = 0;
      while (!mem_req_valid && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      check_mem0_request({label, " physical"}, 1'b1, store_pa,
                         1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1({label, " physical request not probe"}, mem_req_probe, 1'b0);
      tb_check1({label, " physical request pretranslated"},
                mem_req_pretrans, 1'b1);
      tb_check1({label, " physical request nokill"}, mem_req_nokill, 1'b1);
      tb_check1({label, " physical request preserves post-translate class"},
                mem_req_cacheable, probe_cacheable);
      tb_check1({label, " physical request typed attr valid"},
                mem_req_attr_valid, 1'b1);
      tb_check32({label, " physical request exact typed class"},
                 {30'b0, mem_req_class},
                 probe_cacheable ? {30'b0, `OOO_MEM_CLASS_CACHED} :
                                   {30'b0, `OOO_MEM_CLASS_NC});
      `TB_TICK(clk);
      #1;
      tb_check1({label, " physical request fires once"}, mem_req_valid, 1'b0);
      tb_check1({label, " no commit before B"}, commit0_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      mem_rsp_error = b_error;
      #1;
      wait_cycles = 0;
      while (!mem_rsp_ready && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " B response ready"}, mem_rsp_ready, 1'b1);
      tb_check1({label, " B response retains typed attr"},
                tb_mem_rsp_attr_valid, 1'b1);
      tb_check32({label, " B response retains exact class"},
                 {30'b0, tb_mem_rsp_class},
                 probe_cacheable ? {30'b0, `OOO_MEM_CLASS_CACHED} :
                                   {30'b0, `OOO_MEM_CLASS_NC});
      tb_check1({label, " B response owns formal WB"},
                dut.miq_drain_wb_fire_w, 1'b1);
      tb_check1({label, " B formal exception"},
                dut.wb0_exception_w, b_error);
      if (b_error) begin
        tb_check32({label, " B error cause7"},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
        tb_check64({label, " B error tval original VA"},
                   dut.wb0_tval_w, store_va);
      end
      tb_check1({label, " no commit on B/formal-WB"}, commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      mem_rsp_cacheable = 1'b1;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      #1;
      tb_check1({label, " commit after B"}, commit0_valid, 1'b1);
      tb_check1({label, " commit exception"}, commit0_exception, b_error);
      if (b_error) begin
        tb_check32({label, " commit cause7"},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                   {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
        tb_check64({label, " commit tval original VA"},
                   commit0_tval, store_va);
      end
      `TB_TICK(clk);
      #1;
      tb_check1({label, " commit exactly once"}, commit0_valid, 1'b0);
    end
  endtask

  // 【P5 刀 B】IQ dispatch→issue 同拍 bypass 已删除:dispatch 拍只入队(issue_count=2),
  // 次拍从寄存项双发,再次拍 EX/formal-WB；T3W 再下一拍从 ROB Q commit。
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
      tb_check1({label, " no commit0 on formal WB"}, commit0_valid, 1'b0);
      tb_check1({label, " no commit1 on formal WB"}, commit1_valid, 1'b0);
      tb_check1({label, " formal WB0 valid"}, dut.wb0_valid_w, 1'b1);
      tb_check1({label, " formal WB1 valid"}, dut.wb1_valid_w, 1'b1);
      tb_check64({label, " formal WB0 data"}, dut.wb0_data_w, exp0);
      tb_check64({label, " formal WB1 data"}, dut.wb1_data_w, exp1);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " commit0 valid from ROB Q"}, commit0_valid, 1'b1);
      tb_check1({label, " commit1 valid from ROB Q"}, commit1_valid, 1'b1);
      tb_check64({label, " commit0 data from ROB Q"}, commit0_data, exp0);
      tb_check64({label, " commit1 data from ROB Q"}, commit1_data, exp1);
      tb_check32({label, " ROB holds pair through Q commit window"},
                 {27'b0, rob_count}, 32'd2);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " rob drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " iq drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"}, {25'b0, free_count}, 32'd32);
    end
  endtask

  // T3P：两个复杂 fixed-compute uop（当前用于 Zb）不得占 lane1；它们保持
  // ROB/IQ 身份并依次晋升 lane0。与上面的 simple-ALU 双发 helper 分开，避免
  // 测试把旧 lane1 类别所有权误当成功能合同。
  task automatic tick_lane0_serial_pair_to_commit;
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
      tb_check32({label, " pair resident"}, {28'b0, issue_count}, 32'd2);
      tb_check1({label, " older complex owns lane0"},
                dut.issue0_valid_w, 1'b1);
      tb_check1({label, " complex excluded from lane1"},
                dut.issue1_valid_w, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " younger complex remains"},
                 {28'b0, issue_count}, 32'd1);
      tb_check1({label, " first formal WB valid"}, dut.wb0_valid_w, 1'b1);
      tb_check64({label, " first formal WB data"}, dut.wb0_data_w, exp0);
      tb_check1({label, " no first commit on formal WB"},
                commit0_valid, 1'b0);
      tb_check1({label, " younger promoted to lane0"},
                dut.issue0_valid_w, 1'b1);
      tb_check1({label, " promoted complex still not lane1"},
                dut.issue1_valid_w, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " IQ drains after promotion"},
                 {28'b0, issue_count}, 32'd0);
      tb_check1({label, " second formal WB valid"}, dut.wb0_valid_w, 1'b1);
      tb_check64({label, " second formal WB data"}, dut.wb0_data_w, exp1);
      tb_check1({label, " first commit valid from ROB Q"},
                commit0_valid, 1'b1);
      tb_check64({label, " first commit data from ROB Q"},
                 commit0_data, exp0);
      tb_check1({label, " younger cannot retire beside older before Q"},
                commit1_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " second commit valid from ROB Q"},
                commit0_valid, 1'b1);
      tb_check64({label, " second commit data from ROB Q"},
                 commit0_data, exp1);

      `TB_TICK(clk);
      #1;
      tb_check32({label, " ROB drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " IQ remains empty"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " freelist recovers"},
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic wait_commit0_data64;
    input [1023:0] label;
    input [`XLEN-1:0] exp_data;
    input integer max_cycles;
    integer wait_cycles;
    reg formal_wb_seen;
    begin
      wait_cycles = 0;
      formal_wb_seen = 1'b0;
      while (!commit0_valid && (wait_cycles < max_cycles)) begin
        if (dut.wb0_valid_w) begin
          formal_wb_seen = 1'b1;
          tb_check1({label, " no commit on formal WB"},
                    commit0_valid, 1'b0);
          tb_check64({label, " formal WB data"}, dut.wb0_data_w, exp_data);
        end
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " formal WB observed before Q commit"},
                formal_wb_seen, 1'b1);
      tb_check1({label, " commit0 valid"}, commit0_valid, 1'b1);
      tb_check1({label, " commit0 rd en"}, commit0_rd_en, 1'b1);
      if (commit0_valid) begin
        tb_check64({label, " commit0 data"}, commit0_data, exp_data);
      end
      `TB_TICK(clk);
      #1;
      tb_check1({label, " commit exactly once"}, commit0_valid, 1'b0);
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

  // lane1 访存的 IQ pop 与主请求端口必须由同一个 owner/fire 判据驱动。
  // 前一组 RED 锁住 lane0 异常释放端口的真分叉；后一组 guard 固化 WB 等待窗不可达证明。
  task automatic run_lane1_mem_exception_owner_red;
    reg owner_violation;
    reg [ROB_INDEX_W-1:0] lane1_rob;
    begin
      reset_dut();

      set_dispatch0(32'h8000_4ff0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h0000_0301);
      set_dispatch1(32'h8000_4ff4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd1);
      tick_dispatch_to_commit("lane1 owner A base setup", 64'h301, 64'd1);

      set_dispatch0(32'h8000_5000,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd1, 5'd0, 5'd27, 64'd0);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd1,
                                `FUNCT3_LD, 5'd27);
      set_dispatch1(32'h8000_5004,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h8000_0280);
      #1;
      tb_check1("lane1 owner A dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("lane1 owner A dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("lane1 owner A reaches lane0 mem exception",
                dut.issue0_valid_w && dut.issue0_is_mem_w &&
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("lane1 owner A reaches normal lane1 mem offer",
                dut.issue1_valid_w && dut.issue1_is_mem_w &&
                !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w, 1'b1);
      lane1_rob = dut.issue1_rob_idx_w;
      $display("[RED-OBS] lane1-owner-A issue1_fire=%0b req_valid=%0b req_fire=%0b mem_req_valid=%0b",
               dut.issue1_fire_w, dut.issue1_mem_req_valid_w,
               dut.issue1_mem_request_fire_w, mem_req_valid);
      owner_violation =
          dut.issue1_fire_w && dut.issue1_is_mem_w &&
          !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w &&
          !(dut.issue1_mem_request_fire_w &&
            dut.issue1_mem_req_valid_w && mem_req_valid);
      tb_check1("lane1 owner A pop implies matching request fire",
                !owner_violation, 1'b1);
      tb_check1("lane1 owner A request is read", mem_req_write, 1'b0);
      tb_check64("lane1 owner A request address", mem_req_addr,
                 64'h8000_0280);
      tb_check1("lane1 owner A request mux fire",
                dut.mem_req_fire_any_w, 1'b1);
      tb_check1("lane1 owner A selects issue1 owner",
                dut.push_issue1_w, 1'b1);
      tb_check1("lane1 owner A pushes miq", dut.miq_push_valid_w, 1'b1);
      tb_check32("lane1 owner A miq kind is load",
                 {30'b0, dut.miq_push_kind_w}, 32'd0);
      tb_check32("lane1 owner A miq rob matches issue1",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, lane1_rob});
      `TB_TICK(clk);
      #1;
      $display("[RED-OBS] lane1-owner-A post-edge issue_count=%0d rob_count=%0d miq_count=%0d commit0=%0b commit1=%0b",
               issue_count, rob_count, dut.miq_count_w,
               commit0_valid, commit1_valid);
      tb_check1("lane1 owner A miq head valid", dut.miq_head_valid_w, 1'b1);
      tb_check32("lane1 owner A miq head kind is load",
                 {30'b0, dut.miq_head_kind_w}, 32'd0);
      tb_check32("lane1 owner A miq head rob preserved",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_head_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, lane1_rob});
      if (owner_violation) begin
        tb_check32("lane1 owner A violated pair popped from iq",
                   {28'b0, issue_count}, 32'd0);
        tb_check32("lane1 owner A violated lane1 remains unfinished in rob",
                   {27'b0, rob_count}, 32'd2);
        tb_check1("lane1 owner A violated lane1 cannot commit",
                  commit1_valid, 1'b0);
      end
    end
  endtask

  // 审查反例：lane0 虽为本地异常、不占 bridge port，但它若被更老未完成 uop
  // 挡住，lane1 也不能先产生 request。否则 req mux/MIQ 会在 IQ 未 pop 时接收
  // 一个没有 issue owner 的幽灵事务。
  task automatic run_lane1_head_blocked_exception_owner_guard;
    begin
      reset_dut();

      set_dispatch0(32'h8000_5050,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h0000_0301);
      set_dispatch1(32'h8000_5054,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd1);
      tick_dispatch_to_commit("lane1 owner blocked setup", 64'h301, 64'd1);

      // 先让一个更老 CLMUL 离开 IQ、留在长操作单元中，使后续 LR 尚非 ROB head。
      set_dispatch0(32'h8000_5060, make_bitmanip_op_ctrl(),
                    5'd0, 5'd0, 5'd3, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd0, 5'd0, 3'b001, 5'd3);
      #1;
      tb_check1("lane1 owner blocked clmul dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      `TB_TICK(clk);
      #1;
      tb_check32("lane1 owner blocked clmul leaves iq",
                 {28'b0, issue_count}, 32'd0);
      tb_check32("lane1 owner blocked clmul holds rob",
                 {27'b0, rob_count}, 32'd1);
      tb_check1("lane1 owner blocked clmul not complete",
                commit0_valid, 1'b0);

      set_dispatch0(32'h8000_5070,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd1, 5'd0, 5'd27, 64'd0);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd1,
                                `FUNCT3_LD, 5'd27);
      set_dispatch1(32'h8000_5074,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h8000_0280);
      #1;
      tb_check1("lane1 owner blocked dispatch0 ready", dispatch0_ready,
                1'b1);
      tb_check1("lane1 owner blocked dispatch1 ready", dispatch1_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("lane1 owner blocked reaches lane0 mem exception",
                dut.issue0_valid_w && dut.issue0_is_mem_w &&
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("lane1 owner blocked lane0 cannot fire before rob head",
                dut.issue0_mem_can_fire_w, 1'b0);
      tb_check1("lane1 owner blocked port owner is unavailable",
                dut.issue1_mem_port_available_w, 1'b0);
      tb_check1("lane1 owner blocked reaches normal lane1 mem offer",
                dut.issue1_valid_w && dut.issue1_is_mem_w &&
                !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w, 1'b1);
      $display("[RED-OBS] lane1-owner-blocked issue0_can=%0b issue1_ready=%0b issue1_fire=%0b req_valid=%0b req_fire=%0b mem_req_valid=%0b",
               dut.issue0_mem_can_fire_w, dut.issue1_ready_w,
               dut.issue1_fire_w, dut.issue1_mem_req_valid_w,
               dut.issue1_mem_request_fire_w, mem_req_valid);
      tb_check1("lane1 owner blocked holds lane1 in iq",
                dut.issue1_fire_w, 1'b0);
      tb_check1("lane1 owner blocked forbids ownerless req valid",
                dut.issue1_mem_req_valid_w, 1'b0);
      tb_check1("lane1 owner blocked forbids ownerless bridge request",
                mem_req_valid, 1'b0);
      tb_check1("lane1 owner blocked forbids request mux fire",
                dut.mem_req_fire_any_w, 1'b0);
      tb_check1("lane1 owner blocked forbids miq push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("lane1 owner blocked keeps memory pair in iq",
                 {28'b0, issue_count}, 32'd2);
      tb_check32("lane1 owner blocked keeps miq empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check32("lane1 owner blocked keeps three rob entries",
                 {27'b0, rob_count}, 32'd3);
      tb_check1("lane1 owner blocked keeps miq head invalid",
                dut.miq_head_valid_w, 1'b0);
    end
  endtask

  task automatic run_lane1_mem_wb_wait_owner_guard;
    begin
      reset_dut();

      // 先建立一个未返回的 MMIO load(LEGACY)，再让两条 ALU 占满 EX->WB 两口；同拍把
      // 下一组 ALU+load 填入 IQ，从合法接口抵达 rsp-wait 与 lane1 offer 重叠窗。
      set_dispatch0(32'h8000_5100,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd12, 64'h0000_0200);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("lane1 owner B seed legacy request", mem_req_valid, 1'b1);
      `TB_TICK(clk);
      #1;

      set_dispatch0(32'h8000_5110,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd13, 64'd21);
      set_dispatch1(32'h8000_5114,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd14, 64'd22);
      #1;
      tb_check1("lane1 owner B wb-fill dispatch0 ready", dispatch0_ready,
                1'b1);
      tb_check1("lane1 owner B wb-fill dispatch1 ready", dispatch1_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      set_dispatch0(32'h8000_5120,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd15, 64'd23);
      set_dispatch1(32'h8000_5124,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd16, 64'h8000_0280);
      #1;
      tb_check1("lane1 owner B overlap dispatch0 ready", dispatch0_ready,
                1'b1);
      tb_check1("lane1 owner B overlap dispatch1 ready", dispatch1_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;

      tb_check1("lane1 owner B reaches rsp waiting for wb",
                dut.mem_rsp_waiting_for_wb_w, 1'b1);
      tb_check1("lane1 owner B reaches normal lane1 mem offer",
                dut.issue1_valid_w && dut.issue1_is_mem_w &&
                !dut.issue1_mem_exception_w && !dut.issue1_sq_fwd_w, 1'b1);
      $display("[RED-OBS] lane1-owner-B rsp_wait=%0b issue1_ready=%0b issue1_fire=%0b req_valid=%0b req_fire=%0b mem_req_valid=%0b",
               dut.mem_rsp_waiting_for_wb_w, dut.issue1_ready_w,
               dut.issue1_fire_w, dut.issue1_mem_req_valid_w,
               dut.issue1_mem_request_fire_w, mem_req_valid);
      // 静态蕴含链：rsp_wait -> !mem_legacy_slot_open -> !mem_request_slot_open
      // -> !issue1_mem_req_valid。因此该怀疑窗合法接口下不可达，保留动态 guard 防回归。
      tb_check1("lane1 owner B legacy slot closes while rsp waits",
                dut.mem_legacy_slot_open_w, 1'b0);
      tb_check1("lane1 owner B request slot closes while rsp waits",
                dut.mem_request_slot_open_w, 1'b0);
      tb_check1("lane1 owner B cannot request without matching IQ pop",
                dut.issue1_mem_req_valid_w, 1'b0);
    end
  endtask

  // R3.2 integration proof: two independent fixed-latency producers fire
  // together, then two consumers dispatched on that fire edge select on the
  // very next cycle and read the two distinct registered EX payloads.
  task automatic run_r3p2_dual_producer_consumer;
    begin
      reset_dut();

      set_dispatch0(32'h8000_7200,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd11);
      set_dispatch1(32'h8000_7204,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'd22);
      #1;
      tb_check1("R3.2 dual producers lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.2 dual producers lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("R3.2 dual producer0 fires", dut.issue0_fire_w, 1'b1);
      tb_check1("R3.2 dual producer1 fires", dut.issue1_fire_w, 1'b1);

      set_dispatch0(32'h8000_7208,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd7, 64'd1);
      set_dispatch1(32'h8000_720c,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd6, 5'd0, 5'd8, 64'd2);
      #1;
      tb_check1("R3.2 dual consumers lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.2 dual consumers lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("R3.2 consumer0 fires N+1", dut.issue0_fire_w, 1'b1);
      tb_check1("R3.2 consumer1 fires N+1", dut.issue1_fire_w, 1'b1);
      tb_check32("R3.2 consumer0 PC", dut.issue0_pc_w[31:0],
                 32'h8000_7208);
      tb_check32("R3.2 consumer1 PC", dut.issue1_pc_w[31:0],
                 32'h8000_720c);
      tb_check1("R3.2 consumer0 uses EX0", dut.issue0_src1_ex0_fwd_hit_w,
                1'b1);
      tb_check1("R3.2 consumer0 does not use EX1",
                dut.issue0_src1_ex1_fwd_hit_w, 1'b0);
      tb_check1("R3.2 consumer1 uses EX1", dut.issue1_src1_ex1_fwd_hit_w,
                1'b1);
      tb_check64("R3.2 consumer0 forwarded value",
                 dut.issue0_src1_data_w, 64'd11);
      tb_check64("R3.2 consumer1 forwarded value",
                 dut.issue1_src1_value_w, 64'd22);

      `TB_TICK(clk);
      #1;
      tb_check64("R3.2 dual result0", dut.wb0_data_w, 64'd12);
      tb_check64("R3.2 dual result1", dut.wb1_data_w, 64'd24);
      repeat (3) begin
        `TB_TICK(clk);
      end
      #1;
      tb_check32("R3.2 dual ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.2 dual IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("R3.2 dual freelist recovers", {25'b0, free_count},
                 32'd32);
    end
  endtask

  // A nontrivial 64-uop RAW chain is kept one entry ahead of issue.  Every
  // producer is therefore required to fire in cycle N and its consumer in
  // cycle N+1; every consumer must use the registered EX0 payload, and the
  // architectural result sequence must commit as 1..64.
  task automatic run_r3p2_raw_chain_64;
    integer dispatched;
    integer fired;
    integer committed;
    integer cycle_count;
    integer previous_fire_cycle;
    begin
      reset_dut();

      set_dispatch0(32'h8000_a000,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_a004,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd5, 64'd1);
      #1;
      tb_check1("R3.2 chain seed lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.2 chain seed lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);

      dispatched = 2;
      fired = 0;
      committed = 0;
      cycle_count = 0;
      previous_fire_cycle = -1;

      while ((committed < 64) && (cycle_count < 160)) begin
        clear_dispatch();
        if (dispatched < 64) begin
          set_dispatch0(32'h8000_a000 + (dispatched * 4),
                        make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                        5'd5, 5'd0, 5'd5, 64'd1);
        end
        #1;

        if (dispatched < 64) begin
          tb_check1("R3.2 chain continuous dispatch", dispatch0_ready,
                    1'b1);
          if (dispatch0_ready)
            dispatched = dispatched + 1;
        end

        if (fired < 64) begin
          tb_check1("R3.2 chain issue0 fires", dut.issue0_fire_w, 1'b1);
          tb_check1("R3.2 chain never consumes issue1", dut.issue1_fire_w,
                    1'b0);
          if (dut.issue0_fire_w) begin
            tb_check32("R3.2 chain fire PC", dut.issue0_pc_w[31:0],
                       32'h8000_a000 + (fired * 4));
            if (fired != 0) begin
              tb_check32("R3.2 chain producer N to consumer N+1",
                         cycle_count - previous_fire_cycle, 32'd1);
              tb_check1("R3.2 chain registered EX0 hit",
                        dut.issue0_src1_ex0_fwd_hit_w, 1'b1);
              tb_check64("R3.2 chain forwarded value",
                         dut.issue0_src1_data_w, fired);
            end
            previous_fire_cycle = cycle_count;
            fired = fired + 1;
          end
        end

        if (commit0_valid) begin
          tb_check32("R3.2 chain commit PC", commit0_pc[31:0],
                     32'h8000_a000 + (committed * 4));
          tb_check64("R3.2 chain result sequence", commit0_data,
                     committed + 1);
          committed = committed + 1;
        end
        tb_check1("R3.2 chain single commit lane", commit1_valid, 1'b0);

        `TB_TICK(clk);
        cycle_count = cycle_count + 1;
      end
      clear_dispatch();
      #1;

      tb_check32("R3.2 chain dispatched all", dispatched, 32'd64);
      tb_check32("R3.2 chain fired all", fired, 32'd64);
      tb_check32("R3.2 chain committed all", committed, 32'd64);
      tb_check32("R3.2 chain ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.2 chain IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("R3.2 chain freelist recovers", {25'b0, free_count},
                 32'd32);
      $display("[R3.2-RAW64] fired=%0d committed=%0d cycles=%0d",
               fired, committed, cycle_count);
    end
  endtask

  // V9F current-design memory lifecycle.  The plain-memory pair is first
  // captured atomically into two reservation terminals.  In the single-port
  // configuration, an edge-old terminal0 local exception completes first;
  // terminal1 must not look through it, and launches on the following edge
  // with request fire, terminal consume and MIQ owner birth in exact agreement.
  task automatic run_v9f_memory_issue_lifecycle;
    reg [ROB_INDEX_W-1:0] lane1_rob;
    reg [PRODUCER_ID_W-1:0] lane1_producer_id;
    reg [PHY_REG_ADDR_W-1:0] lane1_pdest;
    reg [1:0] lane1_owner_kind;
    reg [4:0] lane1_owner_token;
    reg [1:0] lane1_mmu_epoch;
    reg [`XLEN-1:0] lane1_fault_tval;
    reg [1:0] lane1_size;
    reg lane1_unsigned;
    reg [ROB_INDEX_W-1:0] competing_lane0_rob;
    reg [PRODUCER_ID_W-1:0] competing_lane0_producer_id;
    reg [PHY_REG_ADDR_W-1:0] competing_lane0_pdest;
    reg [4:0] competing_lane0_owner_token;
    reg [4:0] competing_lane1_owner_token;
    integer quiet_i;
    begin
      reset_dut();

      set_dispatch0(32'h8000_4ff0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h8000_0ffd);
      set_dispatch1(32'h8000_4ff4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd1);
      tick_dispatch_to_commit("V9F memory owner base setup",
                              64'h8000_0ffd, 64'd1);
      mem_translate_active = 1'b1;

      // Both uops are ordinary integer loads, so they use the current
      // pair-atomic reservation path.  terminal0 is deliberately misaligned;
      // terminal1 is an aligned cacheable word load.
      set_dispatch0(32'h8000_5000,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd27, 64'h8000_0ffd);
      set_dispatch1(32'h8000_5004,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h8000_0280);
      #1;
      tb_check1("V9F memory pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V9F memory pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("V9F memory pair raw terminal0 select",
                dut.iq_issue0_valid_w, 1'b1);
      tb_check1("V9F memory pair raw terminal1 select",
                dut.issue1_valid_w, 1'b1);
      tb_check1("V9F memory pair atomic capture0",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check1("V9F memory pair atomic capture1",
                dut.mem_issue1_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;

      tb_check1("V9F terminal0 resident", dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V9F terminal1 resident", dut.mem_issue1_res_valid_q, 1'b1);
      $display("[V9F-MEM-DIAG] translate=%0b ea0=%h misaligned0=%0b cross_page0=%0b plain0=%0b exception0=%0b",
               dut.mem_translate_active_i, dut.mem_issue_res_eff_addr_w,
               dut.issue0_mem_misaligned_w, dut.issue0_cross_page_w,
               dut.issue0_plain_ls_w, dut.issue0_mem_exception_w);
      tb_check1("V9F terminal0 is local misaligned exception",
                dut.issue0_is_mem_w && dut.issue0_mem_exception_w, 1'b1);
      tb_check1("V9F terminal1 is normal memory",
                dut.issue1_is_mem_w && !dut.issue1_mem_exception_w &&
                !dut.issue1_sq_fwd_w, 1'b1);
      lane1_rob = dut.mem_issue1_res_rob_idx_q;
      lane1_producer_id = dut.mem_issue1_res_producer_id_q;
      lane1_pdest = dut.mem_issue1_res_pdest_q;
      lane1_owner_kind = dut.mem_issue1_res_owner_kind_q;
      lane1_owner_token = dut.mem_issue1_res_owner_token_q;
      lane1_mmu_epoch = dut.mem_issue1_res_mmu_epoch_q;
      lane1_fault_tval = dut.mem_issue1_res_fault_tval_q;
      lane1_size = dut.mem_issue1_res_ctrl_q[
          `CTRL_MEM_SIZE_MSB:`CTRL_MEM_SIZE_LSB];
      lane1_unsigned = dut.mem_issue1_res_ctrl_q[`CTRL_MEM_UNSIGNED_BIT];
      tb_check1("V9F terminal0 local exception consumes",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("V9F terminal1 held behind edge-old terminal0",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      tb_check1("V9F terminal1 has no early request valid",
                dut.issue1_mem_req_valid_w, 1'b0);
      tb_check1("V9F terminal1 has no early request fire",
                dut.issue1_mem_request_fire_w, 1'b0);
      tb_check1("V9F edge-old terminal0 forbids bridge request fire",
                dut.mem_req_fire_any_w, 1'b0);
      tb_check1("V9F edge-old terminal0 forbids MIQ owner birth",
                dut.miq_push_valid_w, 1'b0);
      $display("[MEM-ISSUE-G1-PHASE0] pair_capture=2 terminal0_local=1 terminal1_hold=1 request_fire=0 miq_birth=0");

      `TB_TICK(clk);
      #1;
      tb_check1("V9F terminal0 cleared after local exception",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("V9F terminal1 remains exact owner",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V9F terminal1 request valid after terminal0 clears",
                dut.issue1_mem_req_valid_w, 1'b1);
      tb_check1("V9F terminal1 request fires",
                dut.issue1_mem_request_fire_w, 1'b1);
      tb_check1("V9F terminal1 consume equals request fire",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      tb_check1("V9F terminal1 owns request mux", dut.push_issue1_w, 1'b1);
      tb_check1("V9F terminal1 request creates MIQ owner",
                dut.miq_push_valid_w, 1'b1);
      tb_check32("V9F terminal1 request owner kind",
                 {30'b0, mem_req_owner_kind}, {30'b0, lane1_owner_kind});
      tb_check32("V9F terminal1 request owner token",
                 {27'b0, mem_req_owner_token}, {27'b0, lane1_owner_token});
      tb_check32("V9F terminal1 request MMU epoch",
                 {30'b0, mem_req_mmu_epoch}, {30'b0, lane1_mmu_epoch});
      tb_check64("V9F terminal1 request fault tval", mem_req_fault_tval,
                 lane1_fault_tval);
      tb_check32("V9F terminal1 MIQ ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, lane1_rob});
      tb_check32("V9F terminal1 MIQ pdest identity",
                 {{(32-PHY_REG_ADDR_W){1'b0}}, dut.miq_push_pdest_w},
                 {{(32-PHY_REG_ADDR_W){1'b0}}, lane1_pdest});
      tb_check1("V9F terminal1 MIQ pdest class",
                dut.miq_push_pdest_fp_w, 1'b0);
      tb_check32("V9F terminal1 MIQ owner kind identity",
                 {30'b0, dut.miq_push_owner_kind_w},
                 {30'b0, lane1_owner_kind});
      tb_check32("V9F terminal1 MIQ token identity",
                 {27'b0, dut.miq_push_owner_token_w},
                 {27'b0, lane1_owner_token});
      tb_check32("V9F terminal1 MIQ epoch identity",
                 {30'b0, dut.miq_push_mmu_epoch_w},
                 {30'b0, lane1_mmu_epoch});
      tb_check64("V9F terminal1 MIQ tval identity",
                 dut.miq_push_fault_tval_w, lane1_fault_tval);
      tb_check32("V9F terminal1 MIQ size identity",
                 {30'b0, dut.miq_push_size_w}, {30'b0, lane1_size});
      tb_check1("V9F terminal1 MIQ unsigned identity",
                dut.miq_push_unsigned_w, lane1_unsigned);
      tb_check64("V9F terminal1 request address", mem_req_addr,
                 64'h8000_0280);
      tb_check1("V9F terminal1 tracker ProducerId identity",
                dut.mem_owner_producer_id_table_w[
                    lane1_owner_token*PRODUCER_ID_W +: PRODUCER_ID_W] ==
                lane1_producer_id, 1'b1);
      $display("[MEM-ISSUE-G1-PHASE1] terminal0_empty=1 terminal1_request_fire=1 terminal1_consume=1 request_mux_owner=1 miq_birth=1 identity_match=1 identity_fields=15");

      `TB_TICK(clk);
      #1;
      tb_check1("V9F terminal1 clears after exact launch",
                dut.mem_issue1_res_valid_q, 1'b0);
      tb_check32("V9F exact request has one MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("V9F MIQ head is exact lane1 owner",
                dut.miq_head_valid_w &&
                (dut.miq_head_rob_w == lane1_rob) &&
                (dut.miq_head_owner_token_w == lane1_owner_token), 1'b1);
      tb_check1("V9F launched terminal has no repeated request",
                dut.issue1_mem_request_fire_w, 1'b0);
      tb_check1("V9F launched terminal has no repeated MIQ birth",
                dut.miq_push_valid_w, 1'b0);
      for (quiet_i = 1; quiet_i < 3; quiet_i = quiet_i + 1) begin
        `TB_TICK(clk);
        #1;
        tb_check1("V9F quiet window keeps terminal1 clear",
                  dut.mem_issue1_res_valid_q, 1'b0);
        tb_check1("V9F quiet window has no repeated request",
                  dut.issue1_mem_request_fire_w, 1'b0);
        tb_check1("V9F quiet window has no repeated MIQ birth",
                  dut.miq_push_valid_w, 1'b0);
        tb_check32("V9F quiet window keeps one MIQ resident",
                   {28'b0, dut.miq_count_w}, 32'd1);
      end
      $display("[MEM-ISSUE-G1-POST-LAUNCH] terminal_cleared=1 repeated_request_fire=0 repeated_miq_birth=0 miq_resident=1 quiet_cycles=3");

      // A global request fire is not sufficient to consume terminal1.  With
      // two aligned loads resident, terminal0 owns the single request port on
      // the first cycle; terminal1 and its complete payload must remain until
      // its own grant/fire on the following cycle.
      reset_dut();
      mem_req_ready = 1'b1;
      set_dispatch0(32'h8000_5080,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd25, 64'h8000_0480);
      set_dispatch1(32'h8000_5084,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd26, 64'h8000_0580);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      `TB_TICK(clk);
      #1;
      competing_lane0_rob = dut.mem_issue_res_rob_idx_q;
      competing_lane0_producer_id = dut.mem_issue_res_producer_id_q;
      competing_lane0_pdest = dut.mem_issue_res_pdest_q;
      competing_lane0_owner_token = dut.mem_issue_res_owner_token_q;
      competing_lane1_owner_token = dut.mem_issue1_res_owner_token_q;
      tb_check1("V9F competing pair has distinct owner tokens",
                competing_lane0_owner_token != competing_lane1_owner_token,
                1'b1);
      tb_check1("V9F competing terminal0 request fires",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check1("V9F competing global request fire is present",
                dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V9F competing request mux selects terminal0",
                dut.push_issue0_w && !dut.push_issue1_w, 1'b1);
      tb_check1("V9F competing terminal0 fire holds terminal1",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V9F competing terminal0 fire does not consume terminal1",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      tb_check1("V9F competing request has one MIQ birth",
                dut.miq_push_valid_w, 1'b1);
      tb_check32("V9F competing request MIQ ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, competing_lane0_rob});
      tb_check32("V9F competing request MIQ pdest identity",
                 {{(32-PHY_REG_ADDR_W){1'b0}}, dut.miq_push_pdest_w},
                 {{(32-PHY_REG_ADDR_W){1'b0}}, competing_lane0_pdest});
      tb_check32("V9F competing request MIQ token identity",
                 {27'b0, dut.miq_push_owner_token_w},
                 {27'b0, competing_lane0_owner_token});
      tb_check64("V9F competing request address identity", mem_req_addr,
                 64'h8000_0480);
      tb_check1("V9F competing request tracker ProducerId identity",
                dut.mem_owner_producer_id_table_w[
                    competing_lane0_owner_token*PRODUCER_ID_W +:
                    PRODUCER_ID_W] == competing_lane0_producer_id, 1'b1);
      tb_check1("V9F competing MIQ birth is not terminal1 identity",
                dut.miq_push_owner_token_w != competing_lane1_owner_token,
                1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V9F competing terminal0 clears",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("V9F competing terminal1 remains for own grant",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V9F competing terminal1 own request fires next",
                dut.issue1_mem_request_fire_w && dut.push_issue1_w, 1'b1);
      tb_check32("V9F competing terminal1 own request token",
                 {27'b0, mem_req_owner_token},
                 {27'b0, competing_lane1_owner_token});
      $display("[MEM-ISSUE-G1-OWNER-ARBITRATION] other_request_fire=1 terminal1_hold=1 terminal1_consume=0 terminal1_birth=0 other_identity_match=1 identity_fields=5 terminal1_release_fire=1 PASS");

      // Ready backpressure is legal request-valid residency.  It must not
      // consume the terminal or create MIQ state until the handshake fires.
      reset_dut();
      set_dispatch0(32'h8000_50f0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h8000_0ffd);
      set_dispatch1(32'h8000_50f4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd1);
      tick_dispatch_to_commit("V9F memory hold base setup",
                              64'h8000_0ffd, 64'd1);
      // Keep this case scoped to request-ready residency.  The lane0 local
      // exception becomes the ROB head before lane1 credit is released; if
      // commit remains enabled, the independent V9O C0 trap barrier correctly
      // suppresses the younger request and masks the backpressure property.
      commit_ready = 1'b0;
      mem_translate_active = 1'b1;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_5100,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd27, 64'h8000_0ffd);
      set_dispatch1(32'h8000_5104,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h8000_0380);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      `TB_TICK(clk);
      #1;
      tb_check1("V9F hold terminal0 local consumes",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("V9F hold terminal1 cannot look through",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V9F backpressured request remains valid",
                dut.issue1_mem_req_valid_w, 1'b1);
      tb_check1("V9F backpressure blocks request fire",
                dut.issue1_mem_request_fire_w, 1'b0);
      tb_check1("V9F backpressure holds terminal1",
                dut.mem_issue1_res_valid_q &&
                !dut.mem_issue1_res_consume_fire_w, 1'b1);
      tb_check1("V9F backpressure forbids MIQ owner birth",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V9F repeated backpressure holds terminal1",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check32("V9F repeated backpressure keeps MIQ empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      mem_req_ready = 1'b1;
      #1;
      tb_check1("V9F released request fires",
                dut.issue1_mem_request_fire_w, 1'b1);
      tb_check1("V9F released request consumes terminal",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      tb_check1("V9F released request creates MIQ owner",
                dut.miq_push_valid_w, 1'b1);
      $display("[MEM-ISSUE-G1-BACKPRESSURE] valid_hold_cycles=2 request_fire_while_blocked=0 terminal_consume_while_blocked=0 miq_birth_while_blocked=0 release_fire=1");

      $display("[MEM-ISSUE-G1-FOCUSED] pair_capture=2 terminal0_local=1 terminal1_hold=1 request_fire=1 terminal1_consume=1 miq_birth=1 identity_match=1 identity_fields=15 backpressure_hold=2 owner_arbitration=1 no_repeat=1 quiet_cycles=3 PASS");
    end
  endtask

  task automatic run_lane1_prf_wb_wakeup;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    begin
      reset_dut();

      // P 与依赖者 A 同拍 dispatch；P 发射的同一拍再 dispatch 依赖者 C。
      // T3M：P 的 WB 拍 A/C 都不得 select；该沿同时写 PRF 与 sticky，N+1
      // 按年龄分别占 issue0/1，并从 regs_q 取得 P 的值。这里证明 issue1 的合法活路径
      // 不依赖 issue0-current-result mux，也为以后重新评估物理删除保留常驻覆盖。
      set_dispatch0(32'h8000_0600,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h1122_3344_5566_7780);
      set_dispatch1(32'h8000_0604,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd7, 5'd0, 5'd8, 64'd5);
      #1;
      tb_check1("lane1 PRF setup dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("lane1 PRF setup dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check32("lane1 PRF setup keeps P/A resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("lane1 PRF P selected alone", dut.issue0_valid_w, 1'b1);
      tb_check32("lane1 PRF P occupies issue0", dut.issue0_pc_w[31:0],
                 32'h8000_0600);
      tb_check1("lane1 PRF A still waits", dut.issue1_valid_w, 1'b0);

      set_dispatch0(32'h8000_0608,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd7, 5'd0, 5'd9, 64'd9);
      #1;
      tb_check1("lane1 PRF C dispatches while P issues", dispatch0_ready,
                1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("lane1 PRF producer WB visible", dut.wb0_valid_w, 1'b1);
      tb_check64("lane1 PRF producer formal WB data",
                 dut.wb0_data_w, 64'h1122_3344_5566_7780);
      producer_pdest = dut.wb0_pdest_w;
      // R3.2 lookahead wake is absorbed at the producer-fire edge, so A
      // and same-edge-dispatched C both select now, while producer formal WB
      // and the matching registered EX payload are visible.
      tb_check1("R3.2 A selects with producer EX", dut.issue0_valid_w, 1'b1);
      tb_check1("R3.2 C selects with producer EX", dut.issue1_valid_w, 1'b1);
      tb_check32("R3.2 A issue PC", dut.issue0_pc_w[31:0], 32'h8000_0604);
      tb_check32("R3.2 C issue PC", dut.issue1_pc_w[31:0], 32'h8000_0608);
      tb_check1("R3.2 A fires", dut.issue0_fire_w, 1'b1);
      tb_check1("R3.2 C fires", dut.issue1_fire_w, 1'b1);
      tb_check32("R3.2 A source tag", {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check32("R3.2 C source tag", {26'b0, dut.issue1_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check1("R3.2 A EX0 hit", dut.issue0_src1_ex0_fwd_hit_w, 1'b1);
      tb_check1("R3.2 C EX0 hit", dut.issue1_src1_ex0_fwd_hit_w, 1'b1);
      tb_check32("R3.2 C forwarded source low",
                 dut.issue1_src1_value_w[31:0], 32'h5566_7780);
      tb_check32("R3.2 C forwarded source high",
                 dut.issue1_src1_value_w[63:32], 32'h1122_3344);

      `TB_TICK(clk);
      #1;
      tb_check1("R3.2 A formal WB visible", dut.wb0_valid_w, 1'b1);
      tb_check1("R3.2 C formal WB visible", dut.wb1_valid_w, 1'b1);
      tb_check1("R3.2 producer commits while consumers WB",
                commit0_valid, 1'b1);
      tb_check64("R3.2 A formal WB data", dut.wb0_data_w,
                 64'h1122_3344_5566_7785);
      tb_check64("R3.2 C formal WB data", dut.wb1_data_w,
                 64'h1122_3344_5566_7789);

      `TB_TICK(clk);
      #1;
      tb_check1("R3.2 A result commits", commit0_valid, 1'b1);
      tb_check1("R3.2 C result commits", commit1_valid, 1'b1);
      tb_check32("R3.2 A result low", commit0_data[31:0], 32'h5566_7785);
      tb_check32("R3.2 A result high", commit0_data[63:32], 32'h1122_3344);
      tb_check32("R3.2 C result low", commit1_data[31:0], 32'h5566_7789);
      tb_check32("R3.2 C result high", commit1_data[63:32], 32'h1122_3344);

      `TB_TICK(clk);
      #1;
      tb_check32("lane1 PRF ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("lane1 PRF IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("lane1 PRF freelist recovers", {25'b0, free_count}, 32'd32);
    end
  endtask

  // T3B 集成契约：MulDiv/CLMUL 的 formal WB 仍负责 ROB done、PRF 正式写入和
  // IQ ready 状态更新，但不能回灌 select/PRF fast payload。依赖者必须在响应拍
  // 保持等待，下一拍才从已登记的 PRF 值发射。
  task automatic run_t3b_divu_wb0_isolation;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    begin
      reset_dut();

      set_dispatch0(32'h8000_6400, make_muldiv_ctrl(),
                    5'd0, 5'd0, 5'd5, 64'd0);
      dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0,
                               3'b101, 5'd5);
      set_dispatch1(32'h8000_6404,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd6, 64'd1);
      #1;
      tb_check1("T3B DIVU WB0 producer dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3B DIVU WB0 dependent dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check32("T3B DIVU WB0 pair resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("T3B DIVU WB0 producer selected",
                dut.issue0_valid_w, 1'b1);
      tb_check32("T3B DIVU WB0 producer PC",
                 dut.issue0_pc_w[31:0], 32'h8000_6400);
      tb_check1("T3B DIVU WB0 dependent waits before response",
                dut.issue1_valid_w, 1'b0);
      producer_pdest = dut.issue0_pdest_w;

      // T3Q：issue 拍只捕获完整 MulDiv request，下一拍才从 buffer Q 初始化；
      // 外部输入清零不得穿透到预处理。
      `TB_TICK(clk);
      #1;
      tb_check1("T3Q DIVU request buffered before preprocess",
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);
      tb_check1("T3Q DIVU buffer has no early response",
                dut.muldiv_resp_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU response maps formal WB0",
                dut.muldiv_rsp_to_wb0_w, 1'b1);
      tb_check1("T3B DIVU formal WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check32("T3B DIVU formal WB0 pdest",
                 {26'b0, dut.wb0_pdest_w}, {26'b0, producer_pdest});
      tb_check64("T3B DIVU formal WB0 data",
                 dut.wb0_data_w, 64'hffff_ffff_ffff_ffff);
      tb_check1("T3B DIVU producer does not commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3B DIVU dependent cannot select on response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B DIVU dependent remains resident on response",
                 {28'b0, issue_count}, 32'd1);

      // formal WB 在该上升沿写 PRF/ready；响应后的 N+1 周期才允许发射。
      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU dependent selects at N+1",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B DIVU producer commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B DIVU producer commit data from ROB Q",
                 commit0_data, 64'hffff_ffff_ffff_ffff);
      tb_check32("T3B DIVU dependent PC at N+1",
                 dut.issue0_pc_w[31:0], 32'h8000_6404);
      tb_check32("T3B DIVU dependent source tag",
                 {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check64("T3B DIVU dependent reads registered PRF",
                 dut.issue0_src1_data_w, 64'hffff_ffff_ffff_ffff);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU dependent formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B DIVU dependent formal WB result",
                 dut.wb0_data_w, 64'd0);
      tb_check1("T3B DIVU dependent does not commit on formal WB",
                commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU dependent commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B DIVU dependent result from ROB Q",
                 commit0_data, 64'd0);

      `TB_TICK(clk);
      #1;
      tb_check32("T3B DIVU WB0 ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T3B DIVU WB0 IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("T3B DIVU WB0 freelist recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic run_t3b_clmul_wb0_isolation;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    reg early_issue;
    integer wait_cycles;
    begin
      reset_dut();

      set_dispatch0(32'h8000_6500,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'd3);
      set_dispatch1(32'h8000_6504,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd5);
      tick_dispatch_to_commit("T3B CLMUL operand setup", 64'd3, 64'd5);

      set_dispatch0(32'h8000_6510, make_bitmanip_op_ctrl(),
                    5'd1, 5'd2, 5'd3, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd2, 5'd1,
                               `FUNCT3_SLL, 5'd3);
      set_dispatch1(32'h8000_6514,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd3, 5'd0, 5'd4, 64'd1);
      #1;
      tb_check1("T3B CLMUL WB0 producer dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3B CLMUL WB0 dependent dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check32("T3B CLMUL WB0 pair resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("T3B CLMUL WB0 producer selected",
                dut.issue0_valid_w, 1'b1);
      tb_check32("T3B CLMUL WB0 producer PC",
                 dut.issue0_pc_w[31:0], 32'h8000_6510);
      producer_pdest = dut.issue0_pdest_w;

      `TB_TICK(clk);
      #1;
      early_issue = 1'b0;
      wait_cycles = 0;
      while (!dut.clmul_rsp_to_wb0_w && (wait_cycles < 70)) begin
        if (dut.issue0_valid_w || dut.issue1_valid_w)
          early_issue = 1'b1;
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      if (dut.issue0_valid_w || dut.issue1_valid_w)
        early_issue = 1'b1;

      tb_check1("T3B CLMUL dependent never selects before response",
                early_issue, 1'b0);
      tb_check1("T3B CLMUL response reaches formal WB0",
                dut.clmul_rsp_to_wb0_w, 1'b1);
      tb_check1("T3B CLMUL formal WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check32("T3B CLMUL formal WB0 pdest",
                 {26'b0, dut.wb0_pdest_w}, {26'b0, producer_pdest});
      tb_check64("T3B CLMUL formal WB0 data",
                 dut.wb0_data_w, ref_clmul(2'd0, 64'd3, 64'd5));
      tb_check1("T3B CLMUL producer does not commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3B CLMUL dependent cannot select on response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B CLMUL dependent remains resident on response",
                 {28'b0, issue_count}, 32'd1);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B CLMUL dependent selects at N+1",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B CLMUL producer commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B CLMUL producer commit data from ROB Q",
                 commit0_data, ref_clmul(2'd0, 64'd3, 64'd5));
      tb_check32("T3B CLMUL dependent PC at N+1",
                 dut.issue0_pc_w[31:0], 32'h8000_6514);
      tb_check32("T3B CLMUL dependent source tag",
                 {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check64("T3B CLMUL dependent reads registered PRF",
                 dut.issue0_src1_data_w, 64'd15);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B CLMUL dependent formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B CLMUL dependent formal WB result",
                 dut.wb0_data_w, 64'd16);
      tb_check1("T3B CLMUL dependent does not commit on formal WB",
                commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B CLMUL dependent commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B CLMUL dependent result from ROB Q",
                 commit0_data, 64'd16);

      `TB_TICK(clk);
      #1;
      tb_check32("T3B CLMUL WB0 ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T3B CLMUL WB0 IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("T3B CLMUL WB0 freelist recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic run_t3b_divu_wb1_isolation;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    begin
      reset_dut();

      // 两条 ready uop 同拍发射：较老 ALU 自然占 WB0，DIVU 除零响应自然落 WB1。
      set_dispatch0(32'h8000_6600,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'd7);
      set_dispatch1(32'h8000_6604, make_muldiv_ctrl(),
                    5'd0, 5'd0, 5'd2, 64'd0);
      dispatch1_inst = inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0,
                               3'b101, 5'd2);
      #1;
      tb_check1("T3B DIVU WB1 older ALU dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3B DIVU WB1 producer dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("T3B DIVU WB1 older ALU selected",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B DIVU WB1 producer selected",
                dut.issue1_valid_w, 1'b1);
      tb_check32("T3B DIVU WB1 producer PC",
                 dut.issue1_pc_w[31:0], 32'h8000_6604);
      producer_pdest = dut.issue1_pdest_w;

      // 生产者正在 issue 时插入依赖者，rename map 已指向其 pdest。
      set_dispatch0(32'h8000_6608,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd2, 5'd0, 5'd3, 64'd1);
      #1;
      tb_check1("T3B DIVU WB1 dependent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      tb_check1("T3Q DIVU WB1 request buffered before preprocess",
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);
      tb_check1("T3Q DIVU WB1 buffer has no early response",
                dut.muldiv_resp_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;

      tb_check1("T3B DIVU response maps formal WB1",
                dut.muldiv_rsp_to_wb1_w, 1'b1);
      tb_check1("T3B DIVU formal WB1 valid", dut.wb1_valid_w, 1'b1);
      tb_check32("T3B DIVU formal WB1 pdest",
                 {26'b0, dut.wb1_pdest_w}, {26'b0, producer_pdest});
      tb_check64("T3B DIVU formal WB1 data",
                 dut.wb1_data_w, 64'hffff_ffff_ffff_ffff);
      tb_check1("T3B DIVU older ALU formal WB0 valid",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B DIVU older ALU formal WB0 data",
                 dut.wb0_data_w, 64'd7);
      tb_check1("T3B DIVU WB1 pair has no commit on formal WB",
                commit0_valid || commit1_valid, 1'b0);
      tb_check1("T3B DIVU WB1 dependent cannot select on response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B DIVU WB1 dependent remains resident",
                 {28'b0, issue_count}, 32'd1);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU WB1 dependent selects at N+1",
                dut.issue0_valid_w, 1'b1);
      tb_check1("T3B DIVU WB1 older ALU commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("T3B DIVU WB1 producer commits from ROB Q",
                commit1_valid, 1'b1);
      tb_check64("T3B DIVU WB1 older ALU commit data",
                 commit0_data, 64'd7);
      tb_check64("T3B DIVU WB1 producer commit data",
                 commit1_data, 64'hffff_ffff_ffff_ffff);
      tb_check32("T3B DIVU WB1 dependent PC at N+1",
                 dut.issue0_pc_w[31:0], 32'h8000_6608);
      tb_check32("T3B DIVU WB1 dependent source tag",
                 {26'b0, dut.issue0_src1_preg_w},
                 {26'b0, producer_pdest});
      tb_check64("T3B DIVU WB1 dependent reads registered PRF",
                 dut.issue0_src1_data_w, 64'hffff_ffff_ffff_ffff);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU WB1 dependent formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check64("T3B DIVU WB1 dependent formal WB result",
                 dut.wb0_data_w, 64'd0);
      tb_check1("T3B DIVU WB1 dependent does not commit on formal WB",
                commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("T3B DIVU WB1 dependent commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3B DIVU WB1 dependent result from ROB Q",
                 commit0_data, 64'd0);

      `TB_TICK(clk);
      #1;
      tb_check32("T3B DIVU WB1 ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T3B DIVU WB1 IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("T3B DIVU WB1 freelist recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  // T3B domain exclusion：整数与 FP 物理寄存器编号空间可以出现相同数值，
  // 但 FP load response 只能写 FP PRF / 广播 fp_wake1，绝不能借 integer formal WB
  // 误唤醒同编号的整数 IQ source。用固定延迟 CLMUL 持有 GPR preg，再让单发
  // FP load 从独立 FP free-list 取得同号 preg，构造真实 tag alias。
  task automatic run_t3b_fp_load_tag_alias_exclusion;
    reg [PHY_REG_ADDR_W-1:0] gpr_pdest;
    reg [PHY_REG_ADDR_W-1:0] fp_pdest;
    begin
      reset_dut();

      // CLMUL 固定运行 64 拍，给后续 FP load response 留出稳定的整数等待窗。
      set_dispatch0(32'h8000_6700, make_bitmanip_op_ctrl(),
                    5'd0, 5'd0, 5'd5, 64'd0);
      dispatch0_inst = inst_op(7'h05, 5'd0, 5'd0,
                               `FUNCT3_SLL, 5'd5);
      #1;
      tb_check1("T3B FP-load alias CLMUL dispatch ready",
                dispatch0_ready, 1'b1);
      gpr_pdest = dut.dispatch0_pdest_w;
      tb_check1("T3B FP-load alias GPR pdest nonzero",
                gpr_pdest != {PHY_REG_ADDR_W{1'b0}}, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3B FP-load alias CLMUL selected",
                dut.issue0_valid_w && dut.issue0_is_clmul_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B FP-load alias CLMUL remains inflight",
                dut.clmul_resp_valid_w, 1'b0);

      // 单发 lane0 FP load 使用 FP alloc0，因此复位后的首个 FPR preg 与上面的
      // 首个 GPR preg 数值相同；两个 free-list 仍是完全独立的状态域。
      set_dispatch0(32'h8000_6704,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h8000_02a0);
      dispatch0_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd9,
                        `OPCODE_LOAD_FP};
      dispatch0_is_fp = 1'b1;
      dispatch0_fp_load = 1'b1;
      dispatch0_fp_double = 1'b1;
      #1;
      tb_check1("T3B FP-load alias dispatch ready", dispatch0_ready, 1'b1);
      fp_pdest = dut.fpld0_new_pdest_w;
      tb_check32("T3B FP-load/GPR numeric tag aliases",
                 {26'b0, fp_pdest}, {26'b0, gpr_pdest});
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S FP-load alias capture has no early request",
                mem_req_valid, 1'b0);
      tb_check1("T3S FP-load alias reservation capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B FP-load alias request visible", mem_req_valid, 1'b1);
      tb_check1("T3B FP-load alias request is read", mem_req_write, 1'b0);
      tb_check32("T3B FP-load alias request address",
                 mem_req_addr[31:0], 32'h8000_02a0);

      // load 发射同拍把真正依赖 CLMUL GPR preg 的整数 uop 放入 IQ。
      set_dispatch0(32'h8000_6708,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd6, 64'd1);
      #1;
      tb_check1("T3B FP-load alias dependent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3B FP-load alias dependent resident",
                 {28'b0, issue_count}, 32'd1);
      tb_check32("T3B FP-load alias dependent source tag",
                 {26'b0, dut.u_dispatch_backend.u_issue_queue.src1_preg_q[0]},
                 {26'b0, gpr_pdest});
      tb_check1("T3B FP-load alias dependent waits before response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0123_4567_89ab_cdef;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3B FP-load alias response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3B FP-load alias classified FP", dut.mem_rsp_fp_load_w,
                1'b1);
      tb_check32("T3B FP-load alias response keeps numeric tag",
                 {26'b0, dut.miq_head_pdest_w}, {26'b0, gpr_pdest});
      tb_check1("T3B FP-load alias FP wake1 valid", dut.fp_wake1_valid_w,
                1'b1);
      tb_check32("T3B FP-load alias FP wake1 tag",
                 {26'b0, dut.fp_wake1_preg_w}, {26'b0, gpr_pdest});
      tb_check32("T3B FP-load alias integer WB0 pdest is p0",
                 {26'b0, dut.wb0_pdest_w}, 32'd0);
      tb_check1("T3B FP-load alias cannot wake integer issue",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B FP-load alias integer resident preserved",
                 {28'b0, issue_count}, 32'd1);
      $display("[T3B-COVERAGE-OBS] fp-load alias gpr_pdest=%0d fp_pdest=%0d int_wb_pdest=%0d int_issue={%0b,%0b}",
               gpr_pdest, fp_pdest, dut.wb0_pdest_w, dut.issue0_valid_w,
               dut.issue1_valid_w);

      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      // 本场景只验证 response 拍跨域隔离；复位清理长操作和未提交依赖者。
      reset_dut();
    end
  endtask

  // T3B fault exclusion：accepted integer load access-fault 仍必须由 formal WB
  // 携带 exception/cause/tval 完成 ROB 身份，但 fault payload 不是合法 operand，
  // response 拍不得使 integer dependent 发射。
  task automatic run_t3b_integer_load_fault_exclusion;
    reg [PHY_REG_ADDR_W-1:0] load_pdest;
    begin
      reset_dut();

      set_dispatch0(32'h8000_6800,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd10, 64'h8000_02c0);
      #1;
      tb_check1("T3B load-fault dispatch ready", dispatch0_ready, 1'b1);
      load_pdest = dut.dispatch0_pdest_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S load-fault capture has no early request",
                mem_req_valid, 1'b0);
      tb_check1("T3S load-fault reservation capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B load-fault request visible", mem_req_valid, 1'b1);
      tb_check1("T3B load-fault request is read", mem_req_write, 1'b0);
      tb_check32("T3B load-fault request address",
                 mem_req_addr[31:0], 32'h8000_02c0);

      // 请求发射同拍插入依赖者，证明 fault response 不会被 fast CAM 消费。
      set_dispatch0(32'h8000_6804,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd10, 5'd0, 5'd11, 64'd1);
      #1;
      tb_check1("T3B load-fault dependent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3B load-fault dependent waits before response",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check32("T3B load-fault dependent resident",
                 {28'b0, issue_count}, 32'd1);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'hfeed_face_dead_beef;
      mem_rsp_error = 1'b1;
      #1;
      tb_check1("T3B load-fault response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3B load-fault maps formal WB0",
                dut.mem_rsp_to_wb0_w, 1'b1);
      tb_check1("T3B load-fault formal WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check32("T3B load-fault formal WB0 pdest",
                 {26'b0, dut.wb0_pdest_w}, {26'b0, load_pdest});
      tb_check1("T3B load-fault formal exception",
                dut.wb0_exception_w, 1'b1);
      tb_check32("T3B load-fault formal cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_LOAD_ACCESS_FAULT});
      tb_check64("T3B load-fault formal tval",
                 dut.wb0_tval_w, 64'h0000_0000_8000_02c0);
      tb_check1("T3B load-fault cannot same-cycle wake dependent",
                dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
      tb_check1("T3B load-fault has no commit on formal WB",
                commit0_valid, 1'b0);
      $display("[T3B-COVERAGE-OBS] load-fault pdest=%0d formal={valid=%0b exc=%0b cause=%0d tval=0x%016h}",
               load_pdest, dut.wb0_valid_w, dut.wb0_exception_w,
               dut.wb0_cause_w, dut.wb0_tval_w);

      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3B load-fault commit visible from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("T3B load-fault commit exception from ROB Q",
                commit0_exception, 1'b1);
      tb_check32("T3B load-fault commit cause from ROB Q",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_LOAD_ACCESS_FAULT});
      tb_check64("T3B load-fault commit tval from ROB Q", commit0_tval,
                 64'h0000_0000_8000_02c0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3B load-fault commits exactly once", commit0_valid, 1'b0);
      reset_dut();
    end
  endtask

  // T4H：桥侧 PMA deny 复用 PROBE response ABI；后端必须把它形成精确
  // store-access-fault，而不是回填/退休 SQ entry 后等待 drain 错误。
  task automatic run_t4h_store_probe_pma_fault_precise;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_68c0;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_1800_0040;
    begin
      reset_dut();
      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      // SQ allocation/retire classification consumes the architectural opcode,
      // while the focused TB supplies ctrl/imm directly.
      dispatch0_inst = 32'h0000_3023;  // sd x0,0(x0)
      #1;
      tb_check1("T4H store-fault dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4H store PMA probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b1, {`STRB_W{1'b1}});
      tb_check1("T4H plain store request is probe",
                dut.mem_req_probe_o, 1'b1);
      `TB_TICK(clk);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_rsp_error = 1'b1;
      #1;
      tb_check1("T4H probe fault response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4H probe fault maps formal WB", dut.mem_rsp_to_wb0_w,
                1'b1);
      tb_check1("T4H probe fault formal exception", dut.wb0_exception_w,
                1'b1);
      tb_check32("T4H probe fault formal cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
      tb_check64("T4H probe fault formal tval", dut.wb0_tval_w, STORE_VA);
      tb_check1("T4H fault probe cannot fill SQ", dut.sq_fill_probe_w,
                1'b0);
      tb_check1("T4H fault probe cannot request drain",
                dut.sq_drain_req_valid_w, 1'b0);
      tb_check1("T4H no commit on formal WB", commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4H store fault commits from ROB Q", commit0_valid, 1'b1);
      tb_check1("T4H store fault commit exception", commit0_exception, 1'b1);
      tb_check32("T4H store fault commit cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
      tb_check64("T4H store fault commit tval", commit0_tval, STORE_VA);
      tb_check1("T4H exception store remains non-drainable",
                dut.sq_drain_req_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T4H store fault commits exactly once", commit0_valid, 1'b0);
      tb_check1("T4H no retired-store bus request", mem_req_valid, 1'b0);
      $display("[T4H-PMA-PRECISE-STORE] cause=7 tval=%h SQ-fill=0 drain=0",
               STORE_VA);
      reset_dut();
    end
  endtask

  // T4N: residual write-side bus error is precise at B, even when translation
  // changed the address.  The physical request uses PA; cause/tval retain
  // store-access-fault/original VA and the write is issued exactly once.
  task automatic run_t4n_store_b_error_precise;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_68e0;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_1040;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_1240;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      #1;
      tb_check1("T4N B-error store dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N B-error probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b1, {`STRB_W{1'b1}});
      tb_check1("T4N B-error first request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);
      #1;
      complete_sq_store_after_probe("T4N B-error store",
                                    STORE_VA, STORE_PA, 1'b1, 1'b1);
      tb_check32("T4N B-error ROB drained", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N B-error SQ drained",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-B-ERROR-PRECISE] va=0x%016h pa=0x%016h cause=7",
               STORE_VA, STORE_PA);
      reset_dut();
    end
  endtask

  // R4 S0: the translation response owns the final PMA/PBMT class.  A PBMT
  // NC/IO store may still translate to PMEM, so the SQ must retain cacheable=0
  // and replay that exact attribute with the later pretranslated ROB-head write.
  task automatic run_r4_s0_store_class_propagation;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_68e8;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_1080;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_1280;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      #1;
      tb_check1("R4 S0 PBMT store dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("R4 S0 PBMT store probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("R4 S0 first request is translation probe",
                mem_req_probe, 1'b1);
      `TB_TICK(clk);
      #1;
      complete_sq_store_after_probe("R4 S0 PBMT-NC store",
                                    STORE_VA, STORE_PA, 1'b0, 1'b0);
      tb_check32("R4 S0 PBMT store ROB drained",
                 {27'b0, rob_count}, 32'd0);
      tb_check32("R4 S0 PBMT store SQ drained",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[R4-S0-STORE-CLASS] va=0x%016h pa=0x%016h cacheable=0 PASS",
               STORE_VA, STORE_PA);
      reset_dut();
    end
  endtask

  // T4N reviewer P1-1: translated plain stores that cross a 4 KiB boundary
  // terminate locally.  They still own an SQ entry, so the local exception
  // event must mark that exact ROB entry terminal before commit0 releases it.
  task automatic run_t4n_page_end_store_local_exception;
    input fp_store_case;
    reg [1023:0] label;
    reg [`XLEN-1:0] store_pc;
    reg [`XLEN-1:0] store_va;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      label = fp_store_case ? "T4N FSD page-end" : "T4N SD page-end";
      store_pc = fp_store_case ? 64'h0000_0000_8000_68f4 :
                                 64'h0000_0000_8000_68f0;
      store_va = fp_store_case ? 64'h0000_0000_4000_2ffc :
                                 64'h0000_0000_4000_1ffc;
      set_dispatch0(store_pc, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, store_va);
      if (fp_store_case) begin
        dispatch0_inst = {7'd0, 5'd0, 5'd0, 3'b011, 5'd0,
                          `OPCODE_STORE_FP};  // fsd f0,0(x0)
        dispatch0_is_fp = 1'b1;
        dispatch0_fp_store = 1'b1;
        dispatch0_fp_double = 1'b1;
        dispatch0_fp_fs2_en = 1'b1;
      end else begin
        dispatch0_inst = 32'h0000_3023;  // sd x0,0(x0)
      end
      #1;
      tb_check1({label, " dispatch ready"}, dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      wait_cycles = 0;
      while (!(dut.mem_issue_res_consume_fire_w &&
               dut.issue0_mem_exception_w) && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1({label, " local exception consumes reservation"},
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1({label, " classified cross-page exception"},
                dut.issue0_xpage_misalign_w, 1'b1);
      tb_check1({label, " produces SQ terminal"},
                dut.sq_terminal_valid_w, 1'b1);
      tb_check32({label, " terminal ROB identity"},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.sq_terminal_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q});
      tb_check1({label, " cannot issue a bridge request"},
                mem_req_valid, 1'b0);
      tb_check32({label, " SQ owner resident before terminal edge"},
                 {29'b0, dut.sq_count_w}, 32'd1);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " formal WB valid"}, dut.wb0_valid_w, 1'b1);
      tb_check1({label, " formal WB exception"}, dut.wb0_exception_w, 1'b1);
      tb_check32({label, " formal WB cause"},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64({label, " formal WB tval"}, dut.wb0_tval_w, store_va);
      tb_check1({label, " no commit on formal WB"}, commit0_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1({label, " commits as exception at commit0"},
                commit0_valid && commit0_exception, 1'b1);
      tb_check1({label, " SQ release is terminal-ready"},
                dut.sq_release_ready_w, 1'b1);
      tb_check1({label, " V9Y exact SQ release mask is nonzero"},
                |dut.sq_owner_release_effective_mask_w, 1'b1);
      tb_check1({label, " V9Y exact SQ release terminalizes final holder"},
                dut.mem_owner_terminalized_o, 1'b1);
      tb_check32({label, " commit cause"},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64({label, " commit tval"}, commit0_tval, store_va);
      `TB_TICK(clk);
      #1;
      tb_check32({label, " ROB released"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " SQ released"}, {29'b0, dut.sq_count_w}, 32'd0);
      tb_check1({label, " never requested memory"}, mem_req_valid, 1'b0);
      $display("[T4N-PAGE-END-STORE-TERMINAL] kind=%s va=0x%016h",
               fp_store_case ? "FSD" : "SD", store_va);
      $display("[V9Y-SQ-EXACT-RELEASE] kind=%s mask_nonzero=1 terminalized=1 PASS",
               fp_store_case ? "FSD" : "SD");
      reset_dut();
    end
  endtask

  // Two independent terminal producers can be live in one cycle: an older
  // accepted physical store receives B while a younger translated SD/FSD
  // terminates locally at the page end.  Both tags must become sticky without
  // backpressuring either producer, then release strictly in ROB order.
  task automatic run_t4n_b_local_terminal_collision;
    input fp_store_case;
    localparam [`XLEN-1:0] OLDER_VA = 64'h0000_0000_4000_3a00;
    localparam [`XLEN-1:0] OLDER_PA = 64'h0000_0000_8000_5a00;
    reg [`XLEN-1:0] younger_va;
    reg [ROB_INDEX_W-1:0] older_rob;
    reg [ROB_INDEX_W-1:0] younger_rob;
    reg older_terminal_seen;
    reg younger_terminal_seen;
    integer wait_cycles;
    integer slot;
    begin
      reset_dut();
      mem_translate_active = 1'b1;

      set_dispatch0(32'h8000_68f6, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, OLDER_VA);
      dispatch0_inst = 32'h0000_3023;
      #1;
      older_rob = dut.dispatch0_rob_idx_w;
      tb_check1("T4N dual-terminal older dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N dual-terminal older probe", 1'b1, OLDER_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N dual-terminal older request is probe",
                mem_req_probe, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = OLDER_PA;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N dual-terminal probe response ready",
                mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      wait_mem0_request("T4N dual-terminal older physical", 1'b1, OLDER_PA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N dual-terminal physical request pretranslated",
                mem_req_pretrans, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N dual-terminal older DRAIN owns MIQ",
                 {28'b0, dut.miq_count_w}, 32'd1);

      younger_va = fp_store_case ? 64'h0000_0000_4000_6ffc :
                                   64'h0000_0000_4000_5ffc;
      set_dispatch0(fp_store_case ? 32'h8000_6902 : 32'h8000_68fe,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, younger_va);
      if (fp_store_case) begin
        dispatch0_inst = {7'd0, 5'd0, 5'd0, 3'b011, 5'd0,
                          `OPCODE_STORE_FP};
        dispatch0_is_fp = 1'b1;
        dispatch0_fp_store = 1'b1;
        dispatch0_fp_double = 1'b1;
        dispatch0_fp_fs2_en = 1'b1;
      end else begin
        dispatch0_inst = 32'h0000_3023;
      end
      #1;
      younger_rob = dut.dispatch0_rob_idx_w;
      tb_check1("T4N dual-terminal younger dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.mem_issue_res_valid_q &&
               dut.issue0_mem_exception_w) && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N dual-terminal local candidate resident",
                dut.mem_issue_res_valid_q && dut.issue0_mem_exception_w, 1'b1);

      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N dual-terminal B response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N dual-terminal response source fires",
                dut.sq_response_terminal_w, 1'b1);
      tb_check1("T4N dual-terminal local source fires",
                dut.sq_local_store_exception_w, 1'b1);
      tb_check1("T4N dual-terminal local consume is not backpressured",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check32("T4N dual-terminal response tag",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_head_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, older_rob});
      tb_check32("T4N dual-terminal local tag",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, younger_rob});
`ifdef T4N_DUAL_TERMINAL_NEGATIVE
      // 非真空 mutation：模拟旧单 terminal/tag mux 丢掉 local port；正常构建
      // 不定义该宏。后续 sticky/release 检查必须稳定转 RED。
      force dut.u_store_queue.terminal1_hit_w = 4'b0000;
      $display("[T4N-DUAL-TERMINAL-NEGATIVE] forced second terminal CAM hit low");
`endif
      `TB_TICK(clk);
`ifdef T4N_DUAL_TERMINAL_NEGATIVE
      release dut.u_store_queue.terminal1_hit_w;
`endif
      mem_rsp_valid = 1'b0;
      #1;

      older_terminal_seen = 1'b0;
      younger_terminal_seen = 1'b0;
      for (slot = 0; slot < 4; slot = slot + 1) begin
        if (dut.sq_snoop_valid_w[slot] && dut.sq_snoop_terminal_w[slot] &&
            (dut.sq_snoop_rob_idx_w[slot*ROB_INDEX_W +: ROB_INDEX_W] ==
             older_rob))
          older_terminal_seen = 1'b1;
        if (dut.sq_snoop_valid_w[slot] && dut.sq_snoop_terminal_w[slot] &&
            (dut.sq_snoop_rob_idx_w[slot*ROB_INDEX_W +: ROB_INDEX_W] ==
             younger_rob))
          younger_terminal_seen = 1'b1;
      end
      tb_check1("T4N dual-terminal older tag sticky",
                older_terminal_seen, 1'b1);
      tb_check1("T4N dual-terminal younger tag sticky",
                younger_terminal_seen, 1'b1);
      tb_check1("T4N dual-terminal older store commits first",
                commit0_valid && !commit0_exception, 1'b1);
      tb_check1("T4N dual-terminal younger cannot commit1",
                commit1_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N dual-terminal younger remains after older release",
                 {29'b0, dut.sq_count_w}, 32'd1);
      tb_check1("T4N dual-terminal younger exception becomes commit0",
                commit0_valid && commit0_exception, 1'b1);
      tb_check64("T4N dual-terminal younger tval", commit0_tval, younger_va);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N dual-terminal ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N dual-terminal SQ drains",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-B-LOCAL-DUAL-TERMINAL] younger=%s older_rob=%0d younger_rob=%0d PASS",
               fp_store_case ? "FSD" : "SD", older_rob, younger_rob);
      reset_dut();
    end
  endtask

  // T4N reviewer P1-2: an older normal ALU may retire, but a younger store
  // exception must remain resident and become commit0 on the following cycle.
  task automatic run_t4n_older_alu_probe_fault_exception_order;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_3400;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_68f8,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'h55);
      set_dispatch1(32'h8000_68fc, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      dispatch1_inst = 32'h0000_3023;
      #1;
      tb_check1("T4N older+fault dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("T4N older+fault dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N younger store fault probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N younger store request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);

      tb_mem_rsp_attr_valid = 1'b0;
      tb_mem_rsp_class = `OOO_MEM_CLASS_RSVD;
      mem_rsp_cacheable = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b1;
      #1;
      wait_cycles = 0;
      while (!mem_rsp_ready && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N younger probe fault response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N pretarget probe fault has invalid attr",
                tb_mem_rsp_attr_valid, 1'b0);
      tb_check32("T4N pretarget probe fault has RSVD poison",
                 {30'b0, tb_mem_rsp_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check1("T4N pretarget probe fault cannot fill SQ",
                dut.sq_fill_valid_w, 1'b0);
      tb_check1("T4N commit held during fault WB", commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      commit_ready = 1'b1;
      #1;
      tb_check1("T4N older normal retires", commit0_valid, 1'b1);
      tb_check1("T4N exception structurally forbidden on commit1",
                commit1_valid, 1'b0);
      tb_check1("T4N no trap before exception becomes head",
                commit0_exception, 1'b0);
      tb_check32("T4N pair remains two-deep before older retire",
                 {27'b0, rob_count}, 32'd2);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N fault store remains after older retire",
                 {27'b0, rob_count}, 32'd1);
      tb_check1("T4N fault store becomes commit0 exception",
                commit0_valid && commit0_exception, 1'b1);
      tb_check1("T4N fault store release ready at commit0",
                dut.sq_release_ready_w, 1'b1);
      tb_check32("T4N fault store cause7",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ACCESS_FAULT});
      tb_check64("T4N fault store original VA", commit0_tval, STORE_VA);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N ordered exception ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N ordered exception SQ drains",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-OLDER-ALU-YOUNGER-STORE-FAULT] commit1 blocked; next-cycle commit0 trap PASS");
      reset_dut();
    end
  endtask

  // T4N reviewer P2: checkpoint restore flushes MIQ, so SQ precommit request
  // grant must be masked in the same combinational cycle.  Otherwise SQ marks
  // request_sent while the matching MIQ push is discarded by its flush arm.
  task automatic run_t4n_sq_checkpoint_restore_no_fire;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_3800;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_4800;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(32'h8000_6908, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      dispatch0_inst = 32'h0000_3023;
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T4N restore store probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_PA;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N restore probe response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check32("T4N restore setup SQ resident",
                 {29'b0, dut.sq_count_w}, 32'd1);
      tb_check1("T4N restore setup physical request eligible",
                dut.sq_drain_valid_w, 1'b1);

      checkpoint_restore = 1'b1;
      mem_req_ready = 1'b1;
      #1;
      tb_check1("T4N restore masks SQ grant", dut.grant_sq_w, 1'b0);
      tb_check1("T4N restore masks external request", mem_req_valid, 1'b0);
      tb_check1("T4N restore forbids SQ request fire",
                dut.sq_drain_req_fire_w, 1'b0);
      tb_check1("T4N restore forbids MIQ push", dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check32("T4N restore clears unlaunched SQ owner with ROB",
                 {29'b0, dut.sq_count_w}, 32'd0);
      tb_check32("T4N restore clears store ROB owner",
                 {27'b0, rob_count}, 32'd0);
      tb_check32("T4N restore leaves MIQ empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("T4N restore leaves no stale physical request",
                mem_req_valid, 1'b0);
      $display("[T4N-CHECKPOINT-RESTORE-SQ-GATE] no fire/owner synchronized clear PASS");
      reset_dut();
    end
  endtask

  // Two stores expose the arbitration counterexample directly: while store1's
  // successful probe fill makes its physical request eligible, store2 is held
  // in the reservation.  SQ must win; store2 may transfer to the buffer but may
  // not report a bridge fire.  Responses/commits then remain in physical order.
  task automatic run_t4n_two_store_priority_order;
    localparam [`XLEN-1:0] VA0 = 64'h0000_0000_4000_2000;
    localparam [`XLEN-1:0] PA0 = 64'h0000_0000_8000_2000;
    localparam [`XLEN-1:0] VA1 = 64'h0000_0000_4000_3000;
    localparam [`XLEN-1:0] PA1 = 64'h0000_0000_8000_3000;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = 1'b1;
      set_dispatch0(32'h8000_6900, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, VA0);
      set_dispatch1(32'h8000_6904, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, VA1);
      #1;
      tb_check1("T4N two-store dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("T4N two-store dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();

      wait_mem0_request("T4N store0 probe", 1'b1, VA0,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N store0 request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);
      // Hold the bridge request side so store1 becomes a resident reservation
      // instead of escaping before store0 probe response creates SQ priority.
      mem_req_ready = 1'b0;
      #1;
      wait_cycles = 0;
      while (!dut.mem_issue1_res_valid_q && (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N store1 resident before store0 fill",
                dut.mem_issue1_res_valid_q, 1'b1);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = PA0;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N store0 probe response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N store0 probe has no WB", dut.mem_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;

      tb_check1("T4N SQ wins request grant", dut.grant_sq_w, 1'b1);
      tb_check1("T4N younger issue loses request grant",
                dut.grant_issue1_w, 1'b0);
      tb_check1("T4N younger has no false request fire",
                dut.issue1_mem_request_fire_w, 1'b0);
      tb_check1("T4N younger transfers to buffer",
                dut.issue1_mem_buffer_fire_w, 1'b1);
      tb_check64("T4N first physical write uses PA0", mem_req_addr, PA0);
      tb_check1("T4N first physical write pretrans", mem_req_pretrans, 1'b1);
      `TB_TICK(clk);
      #1;

      // Buffered store1 probe follows, but store0 remains the only physical
      // write owner until its B terminal/commit.
      tb_check1("T4N buffered store1 probe visible", mem_req_valid, 1'b1);
      tb_check1("T4N buffered store1 is probe", mem_req_probe, 1'b1);
      tb_check64("T4N buffered store1 probe VA", mem_req_addr, VA1);
      tb_check1("T4N store0 cannot commit before B", commit0_valid, 1'b0);
      `TB_TICK(clk);
      #1;

      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N store0 B ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N store0 B owns WB", dut.miq_drain_wb_fire_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N store0 commits after B", commit0_valid, 1'b1);
      tb_check1("T4N store1 cannot commit with store0", commit1_valid, 1'b0);

      // Store1 probe response can fill on the same edge that store0 terminal
      // releases; it still cannot physically write until becoming ROB head.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = PA1;
      #1;
      tb_check1("T4N store1 probe response ready", mem_rsp_ready, 1'b1);
      tb_check1("T4N store1 probe has no WB", dut.mem_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("T4N second physical write visible", mem_req_valid, 1'b1);
      tb_check64("T4N second physical write uses PA1", mem_req_addr, PA1);
      tb_check1("T4N second physical write pretrans", mem_req_pretrans, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T4N second physical write at-most-once", mem_req_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("T4N store1 B ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N store1 commits after B", commit0_valid, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("T4N two-store ROB drained", {27'b0, rob_count}, 32'd0);
      tb_check32("T4N two-store SQ drained", {29'b0, dut.sq_count_w}, 32'd0);
      $display("[T4N-TWO-STORE-ORDER] sq-priority/no-false-fire/order PASS");
      reset_dut();
    end
  endtask

  // S1/T4M/T4N interaction: every ordinary load is unknown-class until bridge
  // translation/PMA.  A younger device candidate must not occupy bridge's
  // device wait while an older filled SQ owner still needs that same bridge
  // for physical write/B; cover both translated PMEM-looking VA and Bare UART.
  task automatic run_t4n_t4m_store_before_device_candidate;
    input translate_mode;
    input [`XLEN-1:0] load_candidate_addr;
    localparam [`XLEN-1:0] STORE_VA = 64'h0000_0000_4000_4000;
    localparam [`XLEN-1:0] STORE_PA = 64'h0000_0000_8000_4000;
    integer wait_cycles;
    begin
      reset_dut();
      mem_translate_active = translate_mode;
      set_dispatch0(32'h8000_6920, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      set_dispatch1(32'h8000_6924,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, load_candidate_addr);
      #1;
      tb_check1("T4N/T4M pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("T4N/T4M pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();

      wait_mem0_request("T4N/T4M older store probe", 1'b1, STORE_VA,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      tb_check1("T4N/T4M older request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      wait_cycles = 0;
      while (!dut.mem_issue1_res_valid_q && (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T4N/T4M younger load resident",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("T4N/T4M resident is load", dut.issue1_is_load_w, 1'b1);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_PA;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T4N/T4M store probe response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;

      tb_check1("T4N/T4M unknown-class younger load blind-blocked",
                dut.issue1_load_waits_for_inflight_store_w, 1'b1);
      tb_check1("T4N/T4M younger load has no request-valid",
                dut.issue1_mem_req_valid_w, 1'b0);
      tb_check1("T4N/T4M older store physical grant", dut.grant_sq_w, 1'b1);
      tb_check64("T4N/T4M older store physical PA", mem_req_addr, STORE_PA);
      `TB_TICK(clk);
      #1;
      tb_check1("T4N/T4M younger load remains resident through write",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("T4N/T4M no younger request before B", mem_req_valid, 1'b0);
      tb_check1("T4N/T4M no store commit before B", commit0_valid, 1'b0);

      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("T4N/T4M store B ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("T4N/T4M store commits after B", commit0_valid, 1'b1);
      // B has made the older SQ entry terminal, so the younger request may be
      // exposed immediately; it still cannot receive IO release until the
      // store commit/release edge makes the load exact ROB head.
      tb_check1("T4N/T4M younger load issues immediately after B terminal",
                mem_req_valid, 1'b1);
      tb_check1("T4N/T4M younger request is read", mem_req_write, 1'b0);
      tb_check1("T4N/T4M younger request is not pretranslated",
                mem_req_pretrans, 1'b0);
      tb_check1("T4N/T4M ordinary load request attr invalid",
                mem_req_attr_valid, 1'b0);
      tb_check32("T4N/T4M ordinary load request class poison",
                 {30'b0, mem_req_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});
      tb_check64("T4N/T4M younger request keeps candidate address",
                 mem_req_addr, load_candidate_addr);
      tb_check1("T4N/T4M no device release before store commit edge",
                mem_req_device_release, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T4N/T4M younger request fires exactly once",
                mem_req_valid, 1'b0);
      tb_check1("T4N/T4M load MIQ owner enables device release",
                mem_req_device_release, 1'b1);
      // Both variants model a post-translation IO response.  The translated
      // variant is the counterexample where a PMEM-looking VA becomes IO.
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_IO;
      mem_rsp_cacheable = 1'b0;
      complete_mem0_response("T4N/T4M younger final-IO load", 64'h55aa,
                             1'b1, 1'b1, 1'b1, 64'h55aa);
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      $display("[T4N-T4M-STORE-BEFORE-DEVICE] translate=%0d store write/B/commit precedes load release PASS",
               translate_mode);
      reset_dut();
    end
  endtask

  // S1 deadlock barrier must retain its safe forwarding escape hatch.  A
  // real older CACHED store is probe-filled but not B-terminal; a fully
  // covered younger Bare load forwards locally while sq_block remains high,
  // never creating a second bridge request.
  task automatic run_s1_sq_forward_bypasses_blind_barrier;
    localparam [`XLEN-1:0] STORE_ADDR = 64'h0000_0000_8000_6a80;
    localparam [`XLEN-1:0] STORE_DATA = 64'h1122_3344_5566_7788;
    localparam [`XLEN-1:0] STORE_PC = 64'h0000_0000_8000_69a0;
    localparam [`XLEN-1:0] LOAD_PC = 64'h0000_0000_8000_69a4;
    reg [ROB_INDEX_W-1:0] load_rob;
    integer wait_cycles;
    integer store_commit_count;
    integer load_commit_count;
    reg load_commit_data_ok;
    integer commit_cycles;
    begin
      reset_dut();

      // Materialize nonzero store data in x1 with a real dual-ALU setup.
      set_dispatch0(32'h8000_6980,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, STORE_DATA);
      set_dispatch1(32'h8000_6984,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'h55);
      tick_dispatch_to_commit("S1 SQ-forward data setup", STORE_DATA, 64'h55);

      set_dispatch0(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd1, 5'd0, STORE_ADDR);
      dispatch0_ctrl[`CTRL_RS2_EN_BIT] = 1'b1;
      dispatch0_inst = 32'h0010_3023;  // sd x1,0(x0)
      #1;
      tb_check1("S1 SQ-forward store dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("S1 SQ-forward store probe", 1'b1, STORE_ADDR,
                        1'b1, STORE_DATA, 1'b1, {`STRB_W{1'b1}});
      tb_check1("S1 SQ-forward first request is probe", mem_req_probe, 1'b1);
      `TB_TICK(clk);

      // Fill CACHED provenance, then backpressure the physical drain so the
      // older entry remains nonterminal during younger load issue.
      mem_req_ready = 1'b0;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_ADDR;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S1 SQ-forward probe response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("S1 SQ-forward older SQ entry nonterminal",
                dut.sq_snoop_valid_w[dut.sq_snoop_head_w] &&
                !dut.sq_snoop_terminal_w[dut.sq_snoop_head_w], 1'b1);
      tb_check1("S1 SQ-forward physical drain held by backpressure",
                dut.grant_sq_w && !dut.sq_drain_req_fire_w, 1'b1);

      set_dispatch0(LOAD_PC, make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd3, STORE_ADDR);
      #1;
      load_rob = dut.dispatch0_rob_idx_w;
      tb_check1("S1 SQ-forward younger load dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!dut.issue0_sq_fwd_w && (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("S1 SQ-forward blind barrier remains asserted",
                dut.issue0_sq_block_r, 1'b1);
      tb_check1("S1 SQ-forward complete cover enables bypass",
                dut.issue0_sq_fwd_w, 1'b1);
      tb_check64("S1 SQ-forward exact local data",
                 dut.issue0_sq_fwd_data_w, STORE_DATA);
      tb_check1("S1 SQ-forward load creates no bridge request",
                dut.issue0_mem_req_valid_w, 1'b0);
      tb_check1("S1 SQ-forward load is locally fireable",
                dut.issue0_mem_can_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S1 SQ-forward exactly one formal WB",
                dut.wb0_valid_w && (dut.wb0_rob_idx_w == load_rob), 1'b1);
      tb_check64("S1 SQ-forward formal WB data", dut.wb0_data_w, STORE_DATA);
      tb_check1("S1 SQ-forward cannot commit ahead of store B",
                commit0_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("S1 SQ-forward formal WB not duplicated",
                !((dut.wb0_valid_w && (dut.wb0_rob_idx_w == load_rob)) ||
                  (dut.wb1_valid_w && (dut.wb1_rob_idx_w == load_rob))),
                1'b1);

      // Finish the older physical store and then observe each architectural
      // commit exactly once; the load may retire beside or just after store.
      mem_req_ready = 1'b1;
      #1;
      tb_check1("S1 SQ-forward physical drain becomes fireable",
                mem_req_valid && mem_req_pretrans, 1'b1);
      tb_check1("S1 SQ-forward drain typed CACHED",
                mem_req_attr_valid &&
                (mem_req_class == `OOO_MEM_CLASS_CACHED), 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S1 SQ-forward physical drain at-most-once",
                mem_req_valid, 1'b0);
      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S1 SQ-forward B response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;

      store_commit_count = 0;
      load_commit_count = 0;
      load_commit_data_ok = 1'b1;
      for (commit_cycles = 0; commit_cycles < 4;
           commit_cycles = commit_cycles + 1) begin
        if (commit0_valid && (commit0_pc == STORE_PC))
          store_commit_count = store_commit_count + 1;
        if (commit0_valid && (commit0_pc == LOAD_PC)) begin
          load_commit_count = load_commit_count + 1;
          if (commit0_data !== STORE_DATA) load_commit_data_ok = 1'b0;
        end
        if (commit1_valid && (commit1_pc == LOAD_PC)) begin
          load_commit_count = load_commit_count + 1;
          if (commit1_data !== STORE_DATA) load_commit_data_ok = 1'b0;
        end
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S1 SQ-forward store commits exactly once",
                 store_commit_count, 32'd1);
      tb_check32("S1 SQ-forward load commits exactly once",
                 load_commit_count, 32'd1);
      tb_check1("S1 SQ-forward commit data exact", load_commit_data_ok, 1'b1);
      tb_check32("S1 SQ-forward ROB drained", {27'b0, rob_count}, 32'd0);
      tb_check32("S1 SQ-forward SQ drained",
                 {29'b0, dut.sq_count_w}, 32'd0);
      $display("[S1-SQ-FORWARD-BYPASS] block=1 fwd=1 local-WB/commit exactly-once PASS");
      reset_dut();
    end
  endtask

  // T4S：FP capacity 只观察 class/payload intent；packet valid 仅在 actual
  // accept 处控制状态更新。定向保留 invalid FP-looking payload，证明它既不
  // 修改 FP rename/IQ/free-list/ROB，也不阻塞另一条合法 lane0 整数 uop。
  task automatic run_t4s_fp_raw_intent_state_isolation;
    reg [3:0] fp_iq_before;
    reg [FREE_COUNT_W-1:0] fp_free_before;
    reg [ROB_COUNT_W-1:0] rob_before;
    reg [ISSUE_COUNT_W-1:0] issue_before;
    reg [FREE_COUNT_W-1:0] int_free_before;
    reg [PHY_REG_ADDR_W-1:0] map7_before;
    reg [PHY_REG_ADDR_W-1:0] map8_before;
    begin
      reset_dut();
      fp_iq_before = dut.u_fp_backend.fp_iq_count_w;
      fp_free_before = dut.u_fp_backend.fp_free_count_w;
      rob_before = rob_count;
      issue_before = issue_count;
      int_free_before = free_count;
      map7_before = dut.u_fp_backend.fp_map_q[7];
      map8_before = dut.u_fp_backend.fp_map_q[8];

      set_fp_binary0(32'h8000_69c0, 7'b0000001,
                     5'd2, 5'd1, 5'd7, 1'b1);
      set_fp_binary1(32'h8000_69c4, 7'b0000001,
                     5'd4, 5'd3, 5'd8, 1'b1);
      dispatch0_valid = 1'b0;
      dispatch1_valid = 1'b0;
      #1;
      tb_check1("T4S invalid arithmetic keeps lane0 raw intent",
                dut.d0_fp_arith_w, 1'b1);
      tb_check1("T4S invalid arithmetic keeps lane1 raw intent",
                dut.d1_fp_arith_w, 1'b1);
      tb_check1("T4S invalid arithmetic no DBE lane0 fire",
                dut.dispatch0_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no DBE lane1 fire",
                dut.dispatch1_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no FP lane0 fire",
                dut.u_fp_backend.disp_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no FP lane1 fire",
                dut.u_fp_backend.disp1_fire_w, 1'b0);
      tb_check1("T4S invalid arithmetic no lane0 allocation",
                dut.u_fp_backend.alloc0_valid_w, 1'b0);
      tb_check1("T4S invalid arithmetic no lane1 allocation",
                dut.u_fp_backend.alloc1_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("T4S invalid arithmetic FP IQ unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T4S invalid arithmetic FP free-list unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T4S invalid arithmetic ROB unchanged",
                 {27'b0, rob_count}, {27'b0, rob_before});
      tb_check32("T4S invalid arithmetic integer IQ unchanged",
                 {28'b0, issue_count}, {28'b0, issue_before});
      tb_check32("T4S invalid arithmetic integer free-list unchanged",
                 {25'b0, free_count}, {25'b0, int_free_before});
      tb_check32("T4S invalid arithmetic lane0 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[7]},
                 {26'b0, map7_before});
      tb_check32("T4S invalid arithmetic lane1 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[8]},
                 {26'b0, map8_before});

      clear_dispatch();
      set_dispatch0(32'h8000_69c8,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0200);
      dispatch0_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd7,
                        `OPCODE_LOAD_FP};
      dispatch0_is_fp = 1'b1;
      dispatch0_fp_load = 1'b1;
      dispatch0_fp_double = 1'b1;
      dispatch0_valid = 1'b0;
      set_dispatch1(32'h8000_69cc,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h8000_0208);
      dispatch1_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd8,
                        `OPCODE_LOAD_FP};
      dispatch1_is_fp = 1'b1;
      dispatch1_fp_load = 1'b1;
      dispatch1_fp_double = 1'b1;
      dispatch1_valid = 1'b0;
      #1;
      tb_check1("T4S invalid load keeps lane0 raw intent",
                dut.u_fp_backend.fpld0_alloc_valid_i, 1'b1);
      tb_check1("T4S invalid load keeps lane1 raw intent",
                dut.u_fp_backend.fpld1_alloc_valid_i, 1'b1);
      tb_check1("T4S invalid load no lane0 fire",
                dut.u_fp_backend.fpld0_fire_w, 1'b0);
      tb_check1("T4S invalid load no lane1 fire",
                dut.u_fp_backend.fpld1_fire_w, 1'b0);
      tb_check1("T4S invalid load no lane0 allocation",
                dut.u_fp_backend.alloc0_valid_w, 1'b0);
      tb_check1("T4S invalid load no lane1 allocation",
                dut.u_fp_backend.alloc1_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("T4S invalid load FP IQ unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T4S invalid load FP free-list unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T4S invalid load ROB unchanged",
                 {27'b0, rob_count}, {27'b0, rob_before});
      tb_check32("T4S invalid load lane0 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[7]},
                 {26'b0, map7_before});
      tb_check32("T4S invalid load lane1 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[8]},
                 {26'b0, map8_before});

      clear_dispatch();
      set_dispatch0(32'h8000_69d0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_69d4,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h8000_0210);
      dispatch1_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd8,
                        `OPCODE_LOAD_FP};
      dispatch1_is_fp = 1'b1;
      dispatch1_fp_load = 1'b1;
      dispatch1_fp_double = 1'b1;
      dispatch1_valid = 1'b0;
      #1;
      tb_check1("T4S invalid lane1 load keeps raw intent",
                dut.u_fp_backend.fpld1_alloc_valid_i, 1'b1);
      tb_check1("T4S valid integer lane0 remains ready",
                dispatch0_ready, 1'b1);
      tb_check1("T4S valid integer lane0 fires",
                dut.dispatch0_fire_w, 1'b1);
      tb_check1("T4S invalid FP-looking lane1 does not fire",
                dut.dispatch1_fire_w, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T4S valid integer adds exactly one ROB entry",
                 {27'b0, rob_count}, {27'b0, rob_before} + 32'd1);
      tb_check32("T4S invalid lane1 keeps FP IQ unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T4S invalid lane1 keeps FP free-list unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T4S invalid lane1 keeps FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[8]},
                 {26'b0, map8_before});
      $display("[T4S-FP-RAW-INTENT] invalid payload state isolation PASS");
      reset_dut();
    end
  endtask

  // T3C RED：通过合法 dispatch 把 FP IQ 填到 7/8。mandatory 双 FP pair 此时
  // 需要两个槽，必须整体阻塞；旧顶层却把 lane1 的 fp_ok=0 当成 valid=0 送给
  // DispatchBackend，导致 lane0 被误判成单发并单边改写 FP rename/IQ/ROB。
  task automatic run_t3c_fp_mandatory_pair_atomicity_red;
    reg [3:0] fp_iq_before;
    reg [FREE_COUNT_W-1:0] fp_free_before;
    reg [ROB_COUNT_W-1:0] rob_before;
    reg [PHY_REG_ADDR_W-1:0] map9_before;
    reg [PHY_REG_ADDR_W-1:0] map10_before;
    reg resource_recovered;
    integer lane0_fire_count;
    integer lane1_fire_count;
    integer wait_cycles;
    begin
      reset_dut();

      // f1 = FDIV.D f0,f0：真实 56-step 长操作，保证随后依赖 f1 的 FADD.D
      // 在填充阶段全部常驻 FP IQ，不依赖任何内部 force。
      set_fp_binary0(32'h8000_6a00, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3C FP seed FDIV dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP seed enters IQ",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd1);
      tb_check1("T3Q FP seed selected at raw IQ boundary",
                dut.u_fp_backend.iq_issue_valid_w, 1'b1);
      tb_check1("T3Q FP issue stage is non-fallthrough",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);

      // 首对依赖者入队时，FDIV 同拍离开 IQ 进入 long-op：1 + 2 - 1 = 2。
      set_fp_binary0(32'h8000_6a10, 7'b0000001,
                     5'd0, 5'd1, 5'd2, 1'b1);
      set_fp_binary1(32'h8000_6a14, 7'b0000001,
                     5'd0, 5'd1, 5'd3, 1'b1);
      #1;
      tb_check1("T3C FP fill pair0 lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("T3C FP fill pair0 lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q FP seed captured in issue stage",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("T3Q FP seed not launched on capture edge",
                dut.u_fp_backend.long_meta_valid_q, 1'b0);
      tb_check32("T3C FP fill count two",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd2);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3C FP seed is long-op inflight",
                dut.u_fp_backend.long_meta_valid_q, 1'b1);
      tb_check1("T3C FP divider busy",
                dut.u_fp_backend.long_div_busy_w, 1'b1);
      tb_check32("T3C FP fill count two",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd2);

      set_fp_binary0(32'h8000_6a18, 7'b0000001,
                     5'd0, 5'd1, 5'd4, 1'b1);
      set_fp_binary1(32'h8000_6a1c, 7'b0000001,
                     5'd0, 5'd1, 5'd5, 1'b1);
      #1;
      tb_check1("T3C FP fill pair1 lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("T3C FP fill pair1 lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP fill count four",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd4);

      set_fp_binary0(32'h8000_6a20, 7'b0000001,
                     5'd0, 5'd1, 5'd6, 1'b1);
      set_fp_binary1(32'h8000_6a24, 7'b0000001,
                     5'd0, 5'd1, 5'd7, 1'b1);
      #1;
      tb_check1("T3C FP fill pair2 lane0 ready", dispatch0_ready, 1'b1);
      tb_check1("T3C FP fill pair2 lane1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP fill count six",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd6);

      set_fp_binary0(32'h8000_6a28, 7'b0000001,
                     5'd0, 5'd1, 5'd8, 1'b1);
      #1;
      tb_check1("T3C FP fill single ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3C FP legal boundary is seven of eight",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w}, 32'd7);
      tb_check32("T3C FP boundary free count",
                 {25'b0, dut.u_fp_backend.fp_free_count_w}, 32'd24);
      tb_check32("T3C FP boundary ROB count",
                 {27'b0, rob_count}, 32'd8);

      // 保持同一 mandatory pair 的 raw-valid，模拟前端在 ready 前不得 pop。
      // 两条均写 FPR 且均依赖 f1；只剩一个 FP IQ slot 时必须 ready={0,0}。
      set_fp_binary0(32'h8000_6a30, 7'b0000001,
                     5'd0, 5'd1, 5'd9, 1'b1);
      set_fp_binary1(32'h8000_6a34, 7'b0000001,
                     5'd0, 5'd1, 5'd10, 1'b1);
      #1;
      fp_iq_before = dut.u_fp_backend.fp_iq_count_w;
      fp_free_before = dut.u_fp_backend.fp_free_count_w;
      rob_before = rob_count;
      map9_before = dut.u_fp_backend.fp_map_q[9];
      map10_before = dut.u_fp_backend.fp_map_q[10];
      lane0_fire_count = 0;
      lane1_fire_count = 0;
      resource_recovered = 1'b0;

      $display("[T3C-RED-OBS] blocked raw_fp_ready={%0b,%0b} top_ready={%0b,%0b} fp_fire={%0b,%0b} fp_iq=%0d fp_free=%0d rob=%0d",
               dut.fp_disp_ready_w, dut.fp_disp1_ready_w,
               dispatch0_ready, dispatch1_ready,
               dut.u_fp_backend.disp_fire_w,
               dut.u_fp_backend.disp1_fire_w,
               dut.u_fp_backend.fp_iq_count_w,
               dut.u_fp_backend.fp_free_count_w, rob_count);
      tb_check1("T3C mandatory pair blocks lane0", dispatch0_ready, 1'b0);
      tb_check1("T3C mandatory pair blocks lane1", dispatch1_ready, 1'b0);
      tb_check1("T3C mandatory pair no FP lane0 fire",
                dut.u_fp_backend.disp_fire_w, 1'b0);
      tb_check1("T3C mandatory pair no FP lane1 fire",
                dut.u_fp_backend.disp1_fire_w, 1'b0);

      if (dispatch0_valid && dispatch0_ready)
        lane0_fire_count = lane0_fire_count + 1;
      if (dispatch1_valid && dispatch1_ready)
        lane1_fire_count = lane1_fire_count + 1;
      `TB_TICK(clk);
      #1;

      $display("[T3C-RED-OBS] blocked-post fp_iq=%0d fp_free=%0d rob=%0d map9=%0d map10=%0d fires={%0d,%0d}",
               dut.u_fp_backend.fp_iq_count_w,
               dut.u_fp_backend.fp_free_count_w, rob_count,
               dut.u_fp_backend.fp_map_q[9],
               dut.u_fp_backend.fp_map_q[10],
               lane0_fire_count, lane1_fire_count);
      tb_check32("T3C blocked FP IQ state unchanged",
                 {28'b0, dut.u_fp_backend.fp_iq_count_w},
                 {28'b0, fp_iq_before});
      tb_check32("T3C blocked FP free state unchanged",
                 {25'b0, dut.u_fp_backend.fp_free_count_w},
                 {25'b0, fp_free_before});
      tb_check32("T3C blocked ROB state unchanged",
                 {27'b0, rob_count}, {27'b0, rob_before});
      tb_check32("T3C blocked lane0 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[9]},
                 {26'b0, map9_before});
      tb_check32("T3C blocked lane1 FP map unchanged",
                 {26'b0, dut.u_fp_backend.fp_map_q[10]},
                 {26'b0, map10_before});

      // raw-valid 保持到资源恢复。修复后，FDIV 完成并释放足够 IQ credit 后，
      // pair 应在同一拍恰好各接收一次；旧 RTL 会重复接收 lane0/饿死 lane1。
      wait_cycles = 0;
      while ((lane1_fire_count == 0) && (wait_cycles < 90)) begin
        if (dut.u_fp_backend.fp_iq_count_w <= 4'd6)
          resource_recovered = 1'b1;
        if (dispatch0_valid && dispatch0_ready)
          lane0_fire_count = lane0_fire_count + 1;
        if (dispatch1_valid && dispatch1_ready)
          lane1_fire_count = lane1_fire_count + 1;
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      clear_dispatch();
      #1;

      $display("[T3C-RED-OBS] recovery wait=%0d recovered=%0b fires={%0d,%0d} fp_iq=%0d fp_free=%0d rob=%0d map9=%0d map10=%0d",
               wait_cycles, resource_recovered,
               lane0_fire_count, lane1_fire_count,
               dut.u_fp_backend.fp_iq_count_w,
               dut.u_fp_backend.fp_free_count_w, rob_count,
               dut.u_fp_backend.fp_map_q[9],
               dut.u_fp_backend.fp_map_q[10]);
      tb_check1("T3C FP IQ resource eventually recovers",
                resource_recovered, 1'b1);
      tb_check32("T3C mandatory lane0 accepted exactly once",
                 lane0_fire_count, 32'd1);
      tb_check32("T3C mandatory lane1 accepted exactly once",
                 lane1_fire_count, 32'd1);
      tb_check1("T3C lane0 FP map updates after atomic accept",
                dut.u_fp_backend.fp_map_q[9] != map9_before, 1'b1);
      tb_check1("T3C lane1 FP map updates after atomic accept",
                dut.u_fp_backend.fp_map_q[10] != map10_before, 1'b1);

      // RED 之后清理长操作/队列，避免污染本文件既有回归；tb_errors 保留。
      reset_dut();
    end
  endtask

  // T3Q issue-packet 边界定向验证：全部场景只通过合法 dispatch/ROB 顺序构造，
  // 不 force 内部信号。更老 FDIV 持有 long 单元，使第二条 FDIV packet 在 stage
  // 自然反压；再分别碰撞全局 flush、older branch kill 与 younger branch kill。
  task automatic run_t3q_fp_issue_stage_contracts;
    reg [FP_ISSUE_PACKET_W-1:0] held_packet;
    reg [ROB_INDEX_W-1:0] held_rob;
    reg [ROB_INDEX_W-1:0] branch_rob;
    reg [ROB_INDEX_W-1:0] younger_fp_rob;
    reg [`INST_W-1:0] expected_inst;
    integer wait_cycles;
    integer hold_cycles;
    begin
      // ---------------------------------------------------------------------
      // A. long-op busy 必须让整包跨多个上升沿冻结；flush 当拍组合屏蔽，
      //    沿后只清 valid（payload 留脏不作检查）。
      // ---------------------------------------------------------------------
      reset_dut();
      set_fp_binary0(32'h8000_6b00, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3Q hold seed FDIV dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.long_div_busy_w &&
               dut.u_fp_backend.long_meta_valid_q) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q hold seed reaches long busy",
                dut.u_fp_backend.long_div_busy_w &&
                dut.u_fp_backend.long_meta_valid_q, 1'b1);

      expected_inst = inst_op_fp(7'b0001101, 5'd0, 5'd0, 3'b000, 5'd2);
      set_fp_binary0(32'h8000_6b04, 7'b0001101,
                     5'd0, 5'd0, 5'd2, 1'b1);
      #1;
      tb_check1("T3Q held FDIV dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.fp_issue_stage_valid_w &&
               (dut.u_fp_backend.issue_inst_w === expected_inst)) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q held FDIV reaches issue stage",
                dut.u_fp_backend.fp_issue_stage_valid_w &&
                (dut.u_fp_backend.issue_inst_w === expected_inst), 1'b1);
      tb_check1("T3Q held FDIV is backpressured",
                dut.u_fp_backend.issue_ready_w, 1'b0);
      tb_check1("T3Q held FDIV does not launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      held_packet = dut.u_fp_backend.fp_issue_stage_down_payload_w;
      held_rob = dut.u_fp_backend.issue_rob_idx_w;

      for (hold_cycles = 0; hold_cycles < 3;
           hold_cycles = hold_cycles + 1) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        tb_check1("T3Q long busy keeps stage valid",
                  dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
        tb_check1("T3Q long busy keeps stage stalled",
                  dut.u_fp_backend.issue_ready_w, 1'b0);
        tb_check1("T3Q stalled packet cannot launch",
                  dut.u_fp_backend.issue_fire_w, 1'b0);
        tb_check_fp_issue_packet("T3Q stalled payload remains frozen",
            dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      end
      $display("[T3Q-FP-STAGE-HOLD] cycles=%0d rob=%0d packet=0x%0h",
               hold_cycles, held_rob, held_packet);

      flush = 1'b1;
      #1;
      tb_check1("T3Q flush collision retains raw q before edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("T3Q flush masks visible issue immediately",
                dut.u_fp_backend.issue_valid_w, 1'b0);
      tb_check1("T3Q flush forbids issue launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check1("T3Q flush forbids IQ refill/pop",
                dut.u_fp_backend.iq_issue_ready_w, 1'b0);
      tb_check_fp_issue_packet("T3Q flush collision preserves pre-edge packet",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q flush clears issue stage after edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);
      tb_check1("T3Q flush clears long metadata",
                dut.u_fp_backend.long_meta_valid_q, 1'b0);
      $display("[T3Q-FP-STAGE-FLUSH] raw_before=1 masked_before=1 raw_after=%0b",
               dut.u_fp_backend.fp_issue_stage_valid_w);

      // ---------------------------------------------------------------------
      // B. branch(ROB1) 与 younger FDIV(ROB2) 同包进入各自 IQ；两条边界同拍
      //    捕获后，resolve q 的合法 kill 必须组合屏蔽并沿清 younger packet。
      //    更老、已在飞的 seed FDIV(ROB0)必须继续存活。
      // ---------------------------------------------------------------------
      reset_dut();
      set_fp_binary0(32'h8000_6b20, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3Q younger-kill seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.long_div_busy_w &&
               dut.u_fp_backend.long_meta_valid_q) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q younger-kill seed reaches long busy",
                dut.u_fp_backend.long_div_busy_w &&
                dut.u_fp_backend.long_meta_valid_q, 1'b1);

      set_dispatch0(32'h8000_6b24, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_bht_idx = 10'h2d1;
      set_fp_binary1(32'h8000_6b28, 7'b0001101,
                     5'd0, 5'd0, 5'd2, 1'b1);
      expected_inst = inst_op_fp(7'b0001101, 5'd0, 5'd0, 3'b000, 5'd2);
      #1;
      tb_check1("T3Q younger-kill branch dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("T3Q younger-kill FP dispatch ready",
                dispatch1_ready, 1'b1);
      branch_rob = dut.dispatch0_rob_idx_w;
      younger_fp_rob = dut.dispatch1_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q younger-kill branch issues legally",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("T3Q younger-kill FP selected at raw IQ boundary",
                dut.u_fp_backend.iq_issue_valid_w, 1'b1);
      tb_check1("T3Q younger-kill stage still non-fallthrough",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q younger-kill resolve q valid", branch_resolve_valid, 1'b1);
      tb_check1("T3Q younger-kill resolve is mispredict",
                branch_resolve_mispredict, 1'b1);
      tb_check32("T3Q younger-kill branch ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}}, branch_rob});
      tb_check1("T3Q younger packet captured before kill edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check32("T3Q younger packet keeps ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.u_fp_backend.issue_rob_idx_w},
                 {{(32-ROB_INDEX_W){1'b0}}, younger_fp_rob});
      tb_check32("T3Q younger packet keeps instruction",
                 dut.u_fp_backend.issue_inst_w, expected_inst);
      tb_check1("T3Q staged FP is younger than branch",
                ((younger_fp_rob - dut.rob_head_idx_w) >
                 (branch_rob - dut.rob_head_idx_w)), 1'b1);
      tb_check1("T3Q younger packet is kill hit",
                dut.u_fp_backend.fp_issue_stage_kill_w, 1'b1);
      tb_check1("T3Q younger kill masks visible issue",
                dut.u_fp_backend.issue_valid_w, 1'b0);
      tb_check1("T3Q younger kill forbids launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check1("T3Q younger kill forbids IQ refill/pop",
                dut.u_fp_backend.iq_issue_ready_w, 1'b0);
      tb_check1("T3Q older long metadata survives kill collision",
                dut.u_fp_backend.long_meta_valid_q, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q younger packet clears after kill edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);
      tb_check1("T3Q older long metadata survives younger kill",
                dut.u_fp_backend.long_meta_valid_q, 1'b1);
      tb_check1("T3Q older long operation remains busy",
                dut.u_fp_backend.long_div_busy_w, 1'b1);
      $display("[T3Q-FP-STAGE-KILL-YOUNGER] branch_rob=%0d fp_rob=%0d raw_after=%0b older_long=%0b",
               branch_rob, younger_fp_rob,
               dut.u_fp_backend.fp_issue_stage_valid_w,
               dut.u_fp_backend.long_meta_valid_q);

      // ---------------------------------------------------------------------
      // C. held FDIV(ROB1) 比 mispredict branch(ROB2) 更老。kill 拍仍须组合
      //    屏蔽执行/refill，但年龄 miss 不得清 packet；kill 沿后 payload 继续 hold。
      // ---------------------------------------------------------------------
      reset_dut();
      set_fp_binary0(32'h8000_6b40, 7'b0001101,
                     5'd0, 5'd0, 5'd1, 1'b1);
      #1;
      tb_check1("T3Q older-survivor seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.long_div_busy_w &&
               dut.u_fp_backend.long_meta_valid_q) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q older-survivor seed reaches long busy",
                dut.u_fp_backend.long_div_busy_w &&
                dut.u_fp_backend.long_meta_valid_q, 1'b1);

      expected_inst = inst_op_fp(7'b0001101, 5'd0, 5'd0, 3'b000, 5'd2);
      set_fp_binary0(32'h8000_6b44, 7'b0001101,
                     5'd0, 5'd0, 5'd2, 1'b1);
      #1;
      tb_check1("T3Q older-survivor held FP dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (!(dut.u_fp_backend.fp_issue_stage_valid_w &&
               (dut.u_fp_backend.issue_inst_w === expected_inst)) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3Q older-survivor packet reaches stage",
                dut.u_fp_backend.fp_issue_stage_valid_w &&
                (dut.u_fp_backend.issue_inst_w === expected_inst), 1'b1);
      held_packet = dut.u_fp_backend.fp_issue_stage_down_payload_w;
      held_rob = dut.u_fp_backend.issue_rob_idx_w;

      set_dispatch0(32'h8000_6b48, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_bht_idx = 10'h16e;
      #1;
      tb_check1("T3Q older-survivor branch dispatch ready",
                dispatch0_ready, 1'b1);
      branch_rob = dut.dispatch0_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q older-survivor branch issues legally",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check_fp_issue_packet("T3Q packet holds while branch issues",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q older-survivor resolve q valid",
                branch_resolve_valid, 1'b1);
      tb_check1("T3Q older-survivor resolve is mispredict",
                branch_resolve_mispredict, 1'b1);
      tb_check32("T3Q older-survivor branch ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}}, branch_rob});
      tb_check1("T3Q survivor is older than branch",
                ((held_rob - dut.rob_head_idx_w) <
                 (branch_rob - dut.rob_head_idx_w)), 1'b1);
      tb_check1("T3Q older packet is kill miss",
                dut.u_fp_backend.fp_issue_stage_kill_w, 1'b0);
      tb_check1("T3Q kill still masks older visible issue",
                dut.u_fp_backend.issue_valid_w, 1'b0);
      tb_check1("T3Q older survivor cannot launch on kill",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check1("T3Q older survivor raw stage stays valid",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check_fp_issue_packet("T3Q older survivor packet stable on kill",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3Q older survivor remains after kill edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("T3Q older survivor visible again after kill",
                dut.u_fp_backend.issue_valid_w, 1'b1);
      tb_check1("T3Q older survivor remains backpressured",
                dut.u_fp_backend.issue_ready_w, 1'b0);
      tb_check1("T3Q older survivor still cannot launch",
                dut.u_fp_backend.issue_fire_w, 1'b0);
      tb_check_fp_issue_packet("T3Q older survivor payload holds after kill",
          dut.u_fp_backend.fp_issue_stage_down_payload_w, held_packet);
      $display("[T3Q-FP-STAGE-KILL-OLDER-SURVIVOR] fp_rob=%0d branch_rob=%0d raw_after=%0b payload=0x%0h",
               held_rob, branch_rob,
               dut.u_fp_backend.fp_issue_stage_valid_w, held_packet);

      reset_dut();
    end
  endtask

  // v8f early-wakeup negative: corrupt only the generation carried by a
  // naturally issued producer.  The raw ROB index remains exact and the
  // dependent resident entry must not absorb either early or formal wake.
  task automatic run_v8f_early_wakeup_generation_mismatch;
    reg [PRODUCER_ID_W-1:0] producer_id;
    reg [ROB_INDEX_W-1:0] producer_rob;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    reg [`XLEN-1:0] prf_before;
    reg [`XLEN-1:0] rob_data_before;
    begin
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_1400,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h41);
      set_dispatch1(32'h8000_1404,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd9, 5'd0, 5'd10, 64'h1);
      #1;
      tb_check1("v8f early mismatch producer dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("v8f early mismatch dependent dispatch ready",
                dispatch1_ready, 1'b1);
      producer_id = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      producer_rob = producer_id[ROB_INDEX_W-1:0];
      producer_pdest = dut.dispatch0_pdest_w;
      prf_before = dut.u_phys_reg_file.regs_q[producer_pdest];
      rob_data_before = dut.u_dispatch_backend.u_rob.data_q[producer_rob];

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f early mismatch producer issues",
                dut.issue0_fire_w, 1'b1);
      tb_check1("v8f early mismatch dependent is resident",
                dut.u_dispatch_backend.u_issue_queue.valid_q[1], 1'b1);
      tb_check1("v8f early mismatch dependent starts unready",
                dut.u_dispatch_backend.u_issue_queue.src1_ready_q[1], 1'b0);
      tb_check1("v8f early mismatch exact positive current",
                dut.iq_issue0_producer_current_w, 1'b1);
      tb_check1("v8f early mismatch raw positive control",
                dut.early_wakeup0_raw_valid_w, 1'b1);
      tb_check1("v8f early mismatch exact positive effective",
                dut.early_wakeup0_valid_w, 1'b1);

      v8f_force_producer_id = producer_id;
      v8f_force_producer_id[ROB_INDEX_W] =
          ~producer_id[ROB_INDEX_W];
      force dut.iq_issue0_producer_id_w = v8f_force_producer_id;
      #1;
      tb_check32("v8f early mismatch keeps raw index",
                 {28'b0, dut.iq_issue0_producer_id_w[ROB_INDEX_W-1:0]},
                 {28'b0, producer_rob});
      tb_check1("v8f early mismatch current query rejects generation",
                dut.iq_issue0_producer_current_w, 1'b0);
      tb_check1("v8f early mismatch raw wake remains non-vacuous",
                dut.early_wakeup0_raw_valid_w, 1'b1);
      tb_check1("v8f early mismatch cuts effective wake",
                dut.early_wakeup0_valid_w, 1'b0);
      tb_check1("v8f early mismatch lane1 does not issue",
                dut.issue1_fire_w, 1'b0);
      tb_check1("v8f early mismatch lane1 has no early wake",
                dut.early_wakeup1_valid_w, 1'b0);
      tb_check1("v8f early mismatch has no pre-existing WB0 wake",
                dut.wb0_valid_w, 1'b0);
      tb_check1("v8f early mismatch has no pre-existing WB1 wake",
                dut.wb1_valid_w, 1'b0);
      tb_check1("v8f early mismatch IQ sees gated early0",
                dut.u_dispatch_backend.u_issue_queue.early_wakeup0_valid_i,
                1'b0);
      tb_check1("v8f early mismatch IQ sees quiet early1",
                dut.u_dispatch_backend.u_issue_queue.early_wakeup1_valid_i,
                1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      release dut.iq_issue0_producer_id_w;
      #1;
      tb_check1("v8f early mismatch reaches raw EX0", dut.ex0_valid_q, 1'b1);
      tb_check32("v8f early mismatch PID is carried into EX0",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex0_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, v8f_force_producer_id});
      tb_check1("v8f early mismatch EX0 remains pre-authorized raw",
                dut.ex0_pre_auth_valid_w, 1'b1);
      tb_check1("v8f early mismatch EX0 exact-open rejects",
                dut.ex0_producer_open_w, 1'b0);
      tb_check1("v8f early mismatch EX0 formal WB is cut",
                dut.ex0_wb_valid_w, 1'b0);
      tb_check1("v8f early mismatch dependent remains unready",
                dut.u_dispatch_backend.u_issue_queue.src1_ready_q[0], 1'b0);
      tb_check1("v8f early mismatch has no formal IQ wake",
                dut.u_dispatch_backend.u_issue_queue.wakeup0_valid_i, 1'b0);
      tb_check1("v8f early mismatch has no public completion",
                execute0_valid || execute1_valid, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f early mismatch raw EX0 drains", dut.ex0_valid_q, 1'b0);
      tb_check1("v8f early mismatch dependent stays blocked",
                dut.u_dispatch_backend.u_issue_queue.src1_ready_q[0], 1'b0);
      tb_check64("v8f early mismatch cannot alter PRF",
                 dut.u_phys_reg_file.regs_q[producer_pdest], prf_before);
      tb_check1("v8f early mismatch cannot ready BusyTable",
                dut.u_dispatch_backend.u_busy_table.ready_q[producer_pdest],
                1'b0);
      tb_check1("v8f early mismatch cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[producer_rob], 1'b0);
      tb_check64("v8f early mismatch cannot alter ROB data",
                 dut.u_dispatch_backend.u_rob.data_q[producer_rob],
                 rob_data_before);
      $display("[V8F-EARLY-WAKE-GENERATION-MISMATCH] raw=1 current=0 effective=0 dependent-sticky=0 PASS");
      reset_dut();
    end
  endtask

  // Mirror the issue-time authorization on lane1.  A dependent is dispatched
  // on the same edge as the lane1 producer issues; changing only the carried
  // generation must neither set its sticky ready bit nor let it issue later.
  task automatic run_v8f_early_wakeup1_generation_mismatch;
    reg [PRODUCER_ID_W-1:0] producer_id;
    reg [ROB_INDEX_W-1:0] producer_rob;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    reg [`XLEN-1:0] prf_before;
    reg [`XLEN-1:0] rob_data_before;
    begin
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_1410,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd13, 64'h31);
      set_dispatch1(32'h8000_1414,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd14, 64'h32);
      #1;
      tb_check1("v8f early1 seed lane0 dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("v8f early1 producer dispatch ready",
                dispatch1_ready, 1'b1);
      producer_id = dut.u_dispatch_backend.rob_dispatch1_producer_id_w;
      producer_rob = producer_id[ROB_INDEX_W-1:0];
      producer_pdest = dut.dispatch1_new_pdest_probe_w;
      prf_before = dut.u_phys_reg_file.regs_q[producer_pdest];
      rob_data_before = dut.u_dispatch_backend.u_rob.data_q[producer_rob];

      `TB_TICK(clk);
      clear_dispatch();
      set_dispatch0(32'h8000_1418,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd14, 5'd0, 5'd15, 64'h1);
      #1;
      tb_check1("v8f early1 seed issues lane0", dut.issue0_fire_w, 1'b1);
      tb_check1("v8f early1 producer issues lane1", dut.issue1_fire_w, 1'b1);
      tb_check1("v8f early1 dependent dispatches on issue edge",
                dispatch0_ready, 1'b1);
      tb_check1("v8f early1 exact positive current",
                dut.issue1_producer_current_w, 1'b1);
      tb_check1("v8f early1 raw positive control",
                dut.early_wakeup1_raw_valid_w, 1'b1);
      tb_check1("v8f early1 exact positive effective",
                dut.early_wakeup1_valid_w, 1'b1);

      v8f_force_producer_id = producer_id;
      v8f_force_producer_id[ROB_INDEX_W] =
          ~producer_id[ROB_INDEX_W];
      force dut.issue1_producer_id_w = v8f_force_producer_id;
      #1;
      tb_check32("v8f early1 mismatch keeps raw index",
                 {28'b0, dut.issue1_producer_id_w[ROB_INDEX_W-1:0]},
                 {28'b0, producer_rob});
      tb_check1("v8f early1 mismatch current query rejects generation",
                dut.issue1_producer_current_w, 1'b0);
      tb_check1("v8f early1 mismatch raw wake remains non-vacuous",
                dut.early_wakeup1_raw_valid_w, 1'b1);
      tb_check1("v8f early1 mismatch cuts effective wake",
                dut.early_wakeup1_valid_w, 1'b0);
      tb_check1("v8f early1 mismatch IQ sees gated wake",
                dut.u_dispatch_backend.u_issue_queue.early_wakeup1_valid_i,
                1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      release dut.issue1_producer_id_w;
      #1;
      tb_check1("v8f early1 mismatch dependent is resident",
                dut.u_dispatch_backend.u_issue_queue.valid_q[0], 1'b1);
      tb_check1("v8f early1 mismatch does not stick ready",
                dut.u_dispatch_backend.u_issue_queue.src1_ready_q[0], 1'b0);
      tb_check1("v8f early1 mismatch dependent cannot issue at N+1",
                dut.issue0_fire_w || dut.issue1_fire_w, 1'b0);
      tb_check1("v8f early1 mismatch reaches raw EX1",
                dut.ex1_valid_q, 1'b1);
      tb_check32("v8f early1 mismatch PID is carried into EX1",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex1_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, v8f_force_producer_id});
      tb_check1("v8f early1 mismatch EX1 exact-open rejects",
                dut.ex1_producer_open_w, 1'b0);
      tb_check1("v8f early1 mismatch EX1 formal WB is cut",
                dut.ex1_wb_valid_w, 1'b0);
      tb_check1("v8f early1 mismatch has no formal IQ wake",
                dut.u_dispatch_backend.u_issue_queue.wakeup1_valid_i, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f early1 mismatch raw EX1 drains",
                dut.ex1_valid_q, 1'b0);
      tb_check1("v8f early1 mismatch dependent stays blocked",
                dut.u_dispatch_backend.u_issue_queue.src1_ready_q[0], 1'b0);
      tb_check64("v8f early1 mismatch cannot alter PRF",
                 dut.u_phys_reg_file.regs_q[producer_pdest], prf_before);
      tb_check1("v8f early1 mismatch cannot ready BusyTable",
                dut.u_dispatch_backend.u_busy_table.ready_q[producer_pdest],
                1'b0);
      tb_check1("v8f early1 mismatch cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[producer_rob], 1'b0);
      tb_check64("v8f early1 mismatch cannot alter ROB data",
                 dut.u_dispatch_backend.u_rob.data_q[producer_rob],
                 rob_data_before);
      $display("[V8F-EARLY1-WAKE-GENERATION-MISMATCH] raw=1 current=0 effective=0 sticky=0 N+1-issue=0 PASS");
      reset_dut();
    end
  endtask

  // v8f EX0 exact-open closure.  First establish a natural exact positive,
  // then flip only the generation at the registered EX boundary.  The
  // forwarding-capable bit stays high, so forwarding suppression is not
  // vacuous.  A raw MulDiv response proves that stale EX0 conservatively
  // reserves only WB0 while the physically free WB1 remains usable.
  task automatic run_v8f_ex0_completion_generation_mismatch;
    reg [PRODUCER_ID_W-1:0] producer_id;
    reg [ROB_INDEX_W-1:0] producer_rob;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    reg [`XLEN-1:0] prf_before;
    reg [`XLEN-1:0] rob_data_before;
    begin
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_1420,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd11, 64'h52);
      #1;
      producer_id = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      producer_rob = producer_id[ROB_INDEX_W-1:0];
      producer_pdest = dut.dispatch0_pdest_w;
      prf_before = dut.u_phys_reg_file.regs_q[producer_pdest];
      rob_data_before = dut.u_dispatch_backend.u_rob.data_q[producer_rob];
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f EX0 producer issues", dut.issue0_fire_w, 1'b1);
      tb_check1("v8f EX0 exact issue is current",
                dut.iq_issue0_producer_current_w, 1'b1);
      tb_check1("v8f EX0 exact early wake is effective",
                dut.early_wakeup0_valid_w, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f EX0 exact positive raw valid", dut.ex0_valid_q, 1'b1);
      tb_check32("v8f EX0 exact positive carried id",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex0_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, producer_id});
      tb_check1("v8f EX0 exact positive pre-auth",
                dut.ex0_pre_auth_valid_w, 1'b1);
      tb_check1("v8f EX0 exact positive open", dut.ex0_producer_open_w, 1'b1);
      tb_check1("v8f EX0 exact positive WB", dut.ex0_wb_valid_w, 1'b1);
      tb_check1("v8f EX0 forwarding bit is non-vacuous",
                dut.ex0_down_payload_w[144], 1'b1);

      v8f_force_producer_id = producer_id;
      v8f_force_producer_id[ROB_INDEX_W] =
          ~producer_id[ROB_INDEX_W];
      force dut.ex0_producer_id_q = v8f_force_producer_id;
      #1;
      tb_check32("v8f stale EX0 keeps raw index",
                 {28'b0, dut.ex0_rob_idx_q}, {28'b0, producer_rob});
      tb_check1("v8f stale EX0 remains raw valid", dut.ex0_valid_q, 1'b1);
      tb_check1("v8f stale EX0 remains pre-auth", dut.ex0_pre_auth_valid_w, 1'b1);
      tb_check1("v8f stale EX0 exact-open rejects", dut.ex0_producer_open_w, 1'b0);
      tb_check1("v8f stale EX0 formal WB is cut", dut.ex0_wb_valid_w, 1'b0);
      tb_check1("v8f stale EX0 reserves WB0",
                dut.ex0_wb_slot_occupied_w, 1'b1);
      tb_check32("v8f stale EX0 leaves exactly one WB slot free",
                 {30'b0, dut.wb_free_count_w}, 32'd1);
      tb_check1("v8f stale EX0 PRF write is cut",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("v8f stale EX0 registered forward is cut",
                dut.ex0_registered_fwd_valid_w, 1'b0);
      tb_check1("v8f stale EX0 BusyTable wake is cut",
                dut.u_dispatch_backend.u_busy_table.wakeup0_valid_i, 1'b0);
      tb_check1("v8f stale EX0 integer-IQ wake is cut",
                dut.u_dispatch_backend.u_issue_queue.wakeup0_valid_i, 1'b0);
      tb_check1("v8f stale EX0 FP-IQ wake is cut",
                dut.u_fp_backend.int_wake0_valid_i, 1'b0);
      tb_check1("v8f stale EX0 ROB write is cut",
                dut.u_dispatch_backend.u_rob.wb0_valid_i, 1'b0);
      tb_check1("v8f stale EX0 public completion is cut",
                execute0_valid, 1'b0);

      force dut.muldiv_resp_valid_w = 1'b1;
      v8f_force_lower_pid = 7;
      force dut.u_muldiv_unit.producer_id_q = v8f_force_lower_pid;
      force dut.muldiv_completion_rob_open_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd0;
      force dut.muldiv_resp_data_w = 64'h0000_0000_5a5a_0007;
      #1;
      tb_check1("v8f stale EX0 blocks lower source from WB0",
                dut.muldiv_rsp_to_wb0_w, 1'b0);
      tb_check1("v8f lower source uses free WB1",
                dut.muldiv_rsp_to_wb1_w, 1'b1);
      tb_check1("v8f stale EX0 exposes no WB0 completion",
                dut.wb0_valid_w, 1'b0);
      tb_check1("v8f lower source makes WB1 live", dut.wb1_valid_w, 1'b1);
      tb_check32("v8f lower source owns free WB1",
                 {28'b0, dut.wb1_rob_idx_w}, 32'd7);
      tb_check64("v8f lower source WB1 payload is preserved",
                 dut.wb1_data_w, 64'h0000_0000_5a5a_0007);
      release dut.muldiv_resp_valid_w;
      release dut.u_muldiv_unit.producer_id_q;
      release dut.muldiv_completion_rob_open_w;
      release dut.muldiv_resp_pdest_w;
      release dut.muldiv_resp_data_w;
      #1;

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      release dut.ex0_producer_id_q;
      #1;
      tb_check1("v8f stale EX0 raw stage drains", dut.ex0_valid_q, 1'b0);
      tb_check64("v8f stale EX0 cannot alter PRF",
                 dut.u_phys_reg_file.regs_q[producer_pdest], prf_before);
      tb_check1("v8f stale EX0 cannot ready BusyTable",
                dut.u_dispatch_backend.u_busy_table.ready_q[producer_pdest],
                1'b0);
      tb_check1("v8f stale EX0 cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[producer_rob], 1'b0);
      tb_check64("v8f stale EX0 cannot alter ROB data",
                 dut.u_dispatch_backend.u_rob.data_q[producer_rob],
                 rob_data_before);
      $display("[V8F-EX0-PRODUCER-AUTH] stale generation dropped; pre-auth reserves WB0; lower source uses WB1 PASS");
      reset_dut();
    end
  endtask

  // Mirror the registered completion check on EX1.  EX0 remains exact and
  // occupies WB0; stale EX1 reserves WB1 for one cycle, so a held lower source
  // is backpressured until both raw EX stages drain, without lane1 side effects.
  task automatic run_v8f_ex1_completion_generation_mismatch;
    reg [PRODUCER_ID_W-1:0] producer1_id;
    reg [ROB_INDEX_W-1:0] producer1_rob;
    reg [PHY_REG_ADDR_W-1:0] producer1_pdest;
    reg [`XLEN-1:0] prf_before;
    reg [`XLEN-1:0] rob_data_before;
    begin
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_1440,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd12, 64'h63);
      set_dispatch1(32'h8000_1444,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd13, 64'h64);
      #1;
      producer1_id = dut.u_dispatch_backend.rob_dispatch1_producer_id_w;
      producer1_rob = producer1_id[ROB_INDEX_W-1:0];
      producer1_pdest = dut.dispatch1_new_pdest_probe_w;
      prf_before = dut.u_phys_reg_file.regs_q[producer1_pdest];
      rob_data_before = dut.u_dispatch_backend.u_rob.data_q[producer1_rob];
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f EX1 pair issues lane0", dut.issue0_fire_w, 1'b1);
      tb_check1("v8f EX1 pair issues lane1", dut.issue1_fire_w, 1'b1);
      tb_check1("v8f EX1 exact issue current",
                dut.issue1_producer_current_w, 1'b1);
      tb_check1("v8f EX1 exact early wake effective",
                dut.early_wakeup1_valid_w, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f EX1 exact positive EX0 open", dut.ex0_wb_valid_w, 1'b1);
      tb_check1("v8f EX1 exact positive raw valid", dut.ex1_valid_q, 1'b1);
      tb_check32("v8f EX1 exact positive carried id",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex1_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, producer1_id});
      tb_check1("v8f EX1 exact positive open", dut.ex1_producer_open_w, 1'b1);
      tb_check1("v8f EX1 exact positive WB", dut.ex1_wb_valid_w, 1'b1);
      tb_check1("v8f EX1 forwarding bit is non-vacuous",
                dut.ex1_down_payload_w[144], 1'b1);

      v8f_force_producer_id = producer1_id;
      v8f_force_producer_id[ROB_INDEX_W] =
          ~producer1_id[ROB_INDEX_W];
      force dut.ex1_producer_id_q = v8f_force_producer_id;
      #1;
      tb_check32("v8f stale EX1 keeps raw index",
                 {28'b0, dut.ex1_rob_idx_q}, {28'b0, producer1_rob});
      tb_check1("v8f stale EX1 exact-open rejects", dut.ex1_producer_open_w, 1'b0);
      tb_check1("v8f stale EX1 formal WB is cut", dut.ex1_wb_valid_w, 1'b0);
      tb_check1("v8f exact EX0 reserves WB0",
                dut.ex0_wb_slot_occupied_w, 1'b1);
      tb_check1("v8f stale EX1 reserves WB1",
                dut.ex1_wb_slot_occupied_w, 1'b1);
      tb_check32("v8f exact plus stale EX leave no WB slot free",
                 {30'b0, dut.wb_free_count_w}, 32'd0);
      tb_check1("v8f stale EX1 PRF write is cut",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("v8f stale EX1 registered forward is cut",
                dut.ex1_registered_fwd_valid_w, 1'b0);
      tb_check1("v8f stale EX1 BusyTable wake is cut",
                dut.u_dispatch_backend.u_busy_table.wakeup1_valid_i, 1'b0);
      tb_check1("v8f stale EX1 integer-IQ wake is cut",
                dut.u_dispatch_backend.u_issue_queue.wakeup1_valid_i, 1'b0);
      tb_check1("v8f stale EX1 FP-IQ wake is cut",
                dut.u_fp_backend.int_wake1_valid_i, 1'b0);
      tb_check1("v8f stale EX1 ROB write is cut",
                dut.u_dispatch_backend.u_rob.wb1_valid_i, 1'b0);
      tb_check1("v8f stale EX1 public completion is cut",
                execute1_valid, 1'b0);

      force dut.muldiv_resp_valid_w = 1'b1;
      v8f_force_lower_pid = 14;
      force dut.u_muldiv_unit.producer_id_q = v8f_force_lower_pid;
      force dut.muldiv_resp_pdest_w = 6'd0;
      force dut.muldiv_resp_data_w = 64'h0000_0000_6b6b_000e;
      #1;
      tb_check1("v8f stale EX1 leaves exact EX0 on WB0",
                dut.ex0_wb_valid_w && dut.wb0_valid_w, 1'b1);
      tb_check1("v8f stale EX1 blocks lower source from WB1",
                dut.muldiv_rsp_to_wb1_w, 1'b0);
      tb_check1("v8f full pre-auth occupancy backpressures lower source",
                dut.muldiv_resp_ready_w, 1'b0);
      tb_check1("v8f stale EX1 exposes no WB1 completion",
                dut.wb1_valid_w, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      force dut.muldiv_completion_rob_open_w = 1'b1;
      #1;
      tb_check1("v8f stale EX1 raw stage drains", dut.ex1_valid_q, 1'b0);
      tb_check32("v8f drained EX stages restore both WB slots",
                 {30'b0, dut.wb_free_count_w}, 32'd2);
      tb_check1("v8f held lower source becomes ready next cycle",
                dut.muldiv_resp_ready_w, 1'b1);
      tb_check1("v8f held lower source takes restored WB0",
                dut.muldiv_rsp_to_wb0_w, 1'b1);
      tb_check32("v8f held lower source identity is preserved",
                 {28'b0, dut.wb0_rob_idx_w}, 32'd14);
      tb_check64("v8f held lower source payload is preserved",
                 dut.wb0_data_w, 64'h0000_0000_6b6b_000e);
      release dut.muldiv_resp_valid_w;
      release dut.u_muldiv_unit.producer_id_q;
      release dut.muldiv_completion_rob_open_w;
      release dut.muldiv_resp_pdest_w;
      release dut.muldiv_resp_data_w;
      release dut.ex1_producer_id_q;
      #1;
      tb_check64("v8f stale EX1 cannot alter PRF",
                 dut.u_phys_reg_file.regs_q[producer1_pdest], prf_before);
      tb_check1("v8f stale EX1 cannot ready BusyTable",
                dut.u_dispatch_backend.u_busy_table.ready_q[producer1_pdest],
                1'b0);
      tb_check1("v8f stale EX1 cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[producer1_rob], 1'b0);
      tb_check64("v8f stale EX1 cannot alter ROB data",
                 dut.u_dispatch_backend.u_rob.data_q[producer1_rob],
                 rob_data_before);
      $display("[V8F-EX1-PRODUCER-AUTH] stale generation dropped; pre-auth backpressure then exactly-once readiness PASS");
      reset_dut();
    end
  endtask

  // The lane0 memory reservation is a real producer holder, not an index-only
  // queue.  Exercise a naturally nonzero incarnation through capture/hold/
  // flush, then corrupt only its generation on a local terminal and prove the
  // stale raw EX0 drains without any completion side effect.
  task automatic run_v8f_mem_reservation_producer_id_contract;
    reg [PRODUCER_ID_W-1:0] producer_id;
    reg [PRODUCER_ID_W-1:0] held_id;
    reg [ROB_INDEX_W-1:0] producer_rob;
    reg [PHY_REG_ADDR_W-1:0] producer_pdest;
    reg [`XLEN-1:0] prf_before;
    reg [`XLEN-1:0] rob_data_before;
    integer hold_cycle;
    begin
      // Seed slot zero once, then flush the live incarnation.  The next slot
      // zero allocation is generated by the real ROB source with generation 1.
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_1450,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h1);
      #1;
      tb_check1("v8f mem hold generation seed ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      flush = 1'b1;
      `TB_TICK(clk);
      clear_dispatch();
      flush = 1'b0;
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;

      set_dispatch0(32'h8000_1454,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h8000_0350);
      #1;
      producer_id = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      tb_check1("v8f mem hold producer dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("v8f mem hold producer generation is nonzero",
                |producer_id[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f mem hold capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check32("v8f mem hold IQ carries full producer id",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.iq_issue0_producer_id_w},
                 {{(32-PRODUCER_ID_W){1'b0}}, producer_id});
      `TB_TICK(clk);
      #1;
      tb_check1("v8f mem hold reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check32("v8f mem hold reservation captured full producer id",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.mem_issue_res_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, producer_id});
      tb_check32("v8f mem hold raw index is low-bit projection",
                 {28'b0, dut.mem_issue_res_rob_idx_q},
                 {28'b0, producer_id[ROB_INDEX_W-1:0]});
      held_id = dut.mem_issue_res_producer_id_q;
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        tb_check1("v8f mem hold request remains backpressured",
                  mem_req_valid, 1'b1);
        `TB_TICK(clk);
        #1;
        tb_check1("v8f mem hold reservation stays valid",
                  dut.mem_issue_res_valid_q, 1'b1);
        tb_check32("v8f mem hold full producer id stays stable",
                   {{(32-PRODUCER_ID_W){1'b0}},
                    dut.mem_issue_res_producer_id_q},
                   {{(32-PRODUCER_ID_W){1'b0}}, held_id});
      end
      flush = 1'b1;
      `TB_TICK(clk);
      clear_dispatch();
      flush = 1'b0;
      mem_req_ready = 1'b1;
      #1;
      tb_check1("v8f mem hold flush kills reservation",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("v8f mem hold flush prevents request",
                mem_req_valid, 1'b0);

      // Repeat the real nonzero-generation setup for a translated page-end
      // load, whose reservation consumes into the local EX0 terminal.
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_1460,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd10, 64'h2);
      #1;
      tb_check1("v8f mem terminal generation seed ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      flush = 1'b1;
      `TB_TICK(clk);
      clear_dispatch();
      flush = 1'b0;
      commit_ready = 1'b0;
      mem_translate_active = 1'b1;
      mem_req_ready = 1'b0;

      set_dispatch0(32'h8000_1464,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd11, 64'h4000_1ffc);
      #1;
      producer_id = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      producer_rob = producer_id[ROB_INDEX_W-1:0];
      producer_pdest = dut.dispatch0_pdest_w;
      prf_before = dut.u_phys_reg_file.regs_q[producer_pdest];
      rob_data_before = dut.u_dispatch_backend.u_rob.data_q[producer_rob];
      tb_check1("v8f mem terminal producer generation is nonzero",
                |producer_id[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8f mem terminal capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8f mem terminal reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("v8f mem terminal is a local exception",
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("v8f mem terminal consumes reservation",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("v8f mem terminal selects local EX0 source",
                dut.ex0_up_from_mem_w, 1'b1);
      tb_check32("v8f mem terminal exact full id reaches EX0 up",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex0_up_producer_id_w},
                 {{(32-PRODUCER_ID_W){1'b0}}, producer_id});
      tb_check1("v8f mem terminal issues no bridge request",
                mem_req_valid, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("v8f mem terminal consumes reservation exactly once",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("v8f mem terminal reaches raw EX0",
                dut.ex0_valid_q, 1'b1);
      tb_check32("v8f mem terminal registers full reservation id",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex0_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, producer_id});
      tb_check1("v8f mem terminal exact-open positive",
                dut.ex0_producer_open_w, 1'b1);
      tb_check1("v8f mem terminal formal WB positive",
                dut.ex0_wb_valid_w, 1'b1);

      // Corrupt only after the exact reservation payload has crossed the
      // stage boundary, so the reservation capture/hold assertions remain an
      // independent check of the real holder rather than part of the fault.
      v8f_force_producer_id = producer_id;
      v8f_force_producer_id[ROB_INDEX_W] =
          ~producer_id[ROB_INDEX_W];
      force dut.ex0_producer_id_q = v8f_force_producer_id;
      #1;
      tb_check32("v8f stale mem terminal keeps raw EX0 index",
                 {28'b0, dut.ex0_rob_idx_q}, {28'b0, producer_rob});
      tb_check32("v8f stale mem terminal registered full id",
                 {{(32-PRODUCER_ID_W){1'b0}}, dut.ex0_producer_id_q},
                 {{(32-PRODUCER_ID_W){1'b0}}, v8f_force_producer_id});
      tb_check1("v8f stale mem terminal exact-open rejects",
                dut.ex0_producer_open_w, 1'b0);
      tb_check1("v8f stale mem terminal formal WB is cut",
                dut.ex0_wb_valid_w, 1'b0);
      tb_check1("v8f stale mem terminal ROB write is cut",
                dut.u_dispatch_backend.u_rob.wb0_valid_i, 1'b0);
      tb_check1("v8f stale mem terminal PRF write is cut",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("v8f stale mem terminal public completion is cut",
                execute0_valid, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      release dut.ex0_producer_id_q;
      #1;
      tb_check1("v8f stale mem terminal raw EX0 drains",
                dut.ex0_valid_q, 1'b0);
      tb_check64("v8f stale mem terminal cannot alter PRF",
                 dut.u_phys_reg_file.regs_q[producer_pdest], prf_before);
      tb_check1("v8f stale mem terminal cannot ready BusyTable",
                dut.u_dispatch_backend.u_busy_table.ready_q[producer_pdest],
                1'b0);
      tb_check1("v8f stale mem terminal cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[producer_rob], 1'b0);
      tb_check64("v8f stale mem terminal cannot alter ROB data",
                 dut.u_dispatch_backend.u_rob.data_q[producer_rob],
                 rob_data_before);
      $display("[V8F-MEM-RES-PRODUCER-AUTH] nonzero capture/hold/flush/local-terminal/stale-drain PASS");
      reset_dut();
    end
  endtask

  // v8g ingress lease reauthorization: an IQ entry may still carry the same
  // raw ROB slot after that slot's generation changed.  It must be consumed as
  // stale without allocating a token, creating a reservation, or issuing any
  // architectural/memory side effect.
  task automatic run_v8g_mem_ingress_lease_reauth;
    reg [PRODUCER_ID_W-1:0] producer_id;
    reg [ROB_INDEX_W-1:0] producer_rob;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_1470,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd12, 64'h8000_0370);
      #1;
      producer_id = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      producer_rob = producer_id[ROB_INDEX_W-1:0];
      tb_check1("v8g stale ingress dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8g stale ingress reaches memory IQ head",
                dut.iq_issue0_valid_w && dut.iq_issue0_mem_class_w, 1'b1);
      tb_check1("v8g stale ingress starts current",
                dut.iq_issue0_producer_current_w, 1'b1);

      v8f_force_producer_id = producer_id;
      v8f_force_producer_id[ROB_INDEX_W] =
          ~producer_id[ROB_INDEX_W];
      force dut.iq_issue0_producer_id_w = v8f_force_producer_id;
      #1;
      tb_check32("v8g stale ingress preserves raw ROB slot",
                 {28'b0, dut.iq_issue0_rob_idx_w},
                 {28'b0, producer_rob});
      tb_check1("v8g stale ingress rejects full ProducerId",
                dut.iq_issue0_producer_current_w, 1'b0);
      tb_check1("v8g stale ingress cannot capture reservation",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check1("v8g stale ingress selects explicit stale drop",
                dut.mem_issue_res_stale_drop_w, 1'b1);
      tb_check1("v8g stale ingress is consumed without tracker credit",
                dut.iq_issue0_ready_w, 1'b1);
      tb_check32("v8g stale ingress has no owner before drop",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check1("v8g stale ingress has no request before drop",
                mem_req_valid, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      release dut.iq_issue0_producer_id_w;
      #1;
      tb_check32("v8g stale ingress IQ entry drains exactly once",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("v8g stale ingress creates no reservation",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("v8g stale ingress creates no owner token",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check1("v8g stale ingress creates no bridge request",
                mem_req_valid, 1'b0);
      tb_check1("v8g stale ingress cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[producer_rob], 1'b0);
      $display("[V8G-MEM-INGRESS-LEASE] stale full-ID IQ entry drops without token/reservation/request/completion PASS");
      reset_dut();
    end
  endtask

  // Corrupt only the observational tracker tag while preserving the bridge's
  // exact MIQ tuple.  A stale kind or epoch must enter fatal/quarantine: drain
  // transport, but never trust table PID for ROB query, WB, collector death,
  // or normal final-state cleanup.
  task automatic run_v8g_mem_tracker_tag_quarantine;
    reg [4:0] owner_token;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(32'h8000_1480,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd15, 64'h8000_0380);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("v8g tracker quarantine load", 1'b0,
                        64'h8000_0380, 1'b0, {`XLEN{1'b0}},
                        1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      owner_token = dut.miq_head_owner_token_w;
      tb_check32("v8g tracker quarantine MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check32("v8g tracker quarantine owner live",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd1);

      v8g_force_kind_table = dut.mem_owner_kind_table_w;
      v8g_force_kind_table[owner_token*2 +: 2] =
          dut.miq_head_owner_kind_w ^ 2'b01;
      force dut.mem_owner_kind_table_w = v8g_force_kind_table;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1111_2222_3333_4444;
      #1;
      tb_check1("v8g kind mismatch keeps exact bridge tuple",
                dut.miq_pop_owner_match_w, 1'b1);
      tb_check1("v8g kind mismatch rejects tracker tag",
                dut.miq_head_tracker_exact_w, 1'b0);
      tb_check1("v8g kind mismatch blocks ROB completion query",
                dut.mem_completion_query_valid_w, 1'b0);
      tb_check1("v8g kind mismatch is not owner-open",
                dut.mem_owner_open_w, 1'b0);
      tb_check1("v8g kind mismatch enters fatal quarantine",
                dut.mem_fatal_irrevocable_response_w, 1'b1);
      tb_check1("v8g kind mismatch drains transport",
                mem_rsp_ready, 1'b1);
      tb_check1("v8g kind mismatch has no WB", dut.mem_wb_fire_w, 1'b0);
      tb_check1("v8g kind mismatch has no collector death",
                dut.mem_terminal_ingress_valid_w[0], 1'b0);
      tb_check1("v8g kind mismatch cannot normal-final",
                dut.mem_rsp_final_fire_w, 1'b0);
      mem_rsp_valid = 1'b0;
      release dut.mem_owner_kind_table_w;
      #1;

      v8g_force_epoch_table = dut.mem_owner_epoch_table_w;
      v8g_force_epoch_table[owner_token*2 +: 2] =
          dut.miq_head_mmu_epoch_w ^ 2'b01;
      force dut.mem_owner_epoch_table_w = v8g_force_epoch_table;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("v8g epoch mismatch keeps exact bridge tuple",
                dut.miq_pop_owner_match_w, 1'b1);
      tb_check1("v8g epoch mismatch rejects tracker tag",
                dut.miq_head_tracker_exact_w, 1'b0);
      tb_check1("v8g epoch mismatch blocks ROB completion query",
                dut.mem_completion_query_valid_w, 1'b0);
      tb_check1("v8g epoch mismatch enters fatal quarantine",
                dut.mem_fatal_irrevocable_response_w, 1'b1);
      tb_check1("v8g epoch mismatch has no WB", dut.mem_wb_fire_w, 1'b0);
      tb_check1("v8g epoch mismatch has no collector death",
                dut.mem_terminal_ingress_valid_w[0], 1'b0);
      tb_check1("v8g epoch mismatch cannot normal-final",
                dut.mem_rsp_final_fire_w, 1'b0);
      mem_rsp_valid = 1'b0;
      release dut.mem_owner_epoch_table_w;
      #1;
      $display("[V8G-MEM-TRACKER-QUARANTINE] kind/epoch mismatch drains transport with zero ROB/WB/death/final trust PASS");
      reset_dut();
    end
  endtask

  // Keep a second ALU pair resident while the first pair occupies both formal
  // WB ports.  The stalled exact-open response must suppress only lane1, admit
  // issue0, then take the newly free WB1 slot on the next cycle.
  task automatic run_v8g_mem_continuous_wb_competition;
    reg [PRODUCER_ID_W-1:0] load_producer_id;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(32'h8000_1490,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd16, 64'h8000_0390);
      #1;
      load_producer_id = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("v8g continuous WB load", 1'b0,
                        64'h8000_0390, 1'b0, {`XLEN{1'b0}},
                        1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      tb_check32("v8g continuous WB load MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);

      set_dispatch0(32'h8000_1494,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd17, 64'd31);
      set_dispatch1(32'h8000_1498,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd18, 64'd32);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("v8g continuous WB first pair queued",
                 {28'b0, issue_count}, 32'd2);

      set_dispatch0(32'h8000_149c,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd19, 64'd33);
      set_dispatch1(32'h8000_14a0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd20, 64'd34);
      #1;
      tb_check1("v8g continuous WB replacement pair lane0 ready",
                dispatch0_ready, 1'b1);
      tb_check1("v8g continuous WB replacement pair lane1 ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h5566_7788_99aa_bbcc;
      #1;
      tb_check1("v8g continuous WB first pair occupies WB0",
                execute0_valid, 1'b1);
      tb_check1("v8g continuous WB first pair occupies WB1",
                execute1_valid, 1'b1);
      tb_check32("v8g continuous WB replacement pair remains resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("v8g continuous WB response stalls with both ports full",
                mem_rsp_ready, 1'b0);
      tb_check1("v8g continuous WB issue0 remains admissible",
                dut.issue0_fire_w, 1'b1);
      tb_check1("v8g continuous WB lane1 is suppressed while response waits",
                dut.issue1_fire_w, 1'b0);

      `TB_TICK(clk);
      #1;
      tb_check1("v8g continuous WB response becomes ready at N+1",
                mem_rsp_ready, 1'b1);
      tb_check1("v8g continuous WB response owns freed WB1",
                dut.mem_rsp_to_wb1_w, 1'b1);
      tb_check1("v8g continuous WB response formally completes",
                dut.mem_wb_fire_w, 1'b1);
      tb_check1("v8g continuous WB ROB is unfinished before completion edge",
                dut.u_dispatch_backend.u_rob.done_q[
                  load_producer_id[ROB_INDEX_W-1:0]], 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("v8g continuous WB response marks exact ROB done",
                dut.u_dispatch_backend.u_rob.done_q[
                  load_producer_id[ROB_INDEX_W-1:0]], 1'b1);
      $display("[V8G-MEM-CONTINUOUS-WB-COMPETITION] resident issue0/lane1 pair leaves WB1 for exact response at N+1 PASS");
      reset_dut();
    end
  endtask

  // v8d：不用 force 构造真实 branch+ALU 双发。branch 在 EX0 形成 mispredict
  // boundary 的同拍，严格年轻的 EX1 raw completion 已驻留，但不得穿过
  // formal-WB/PRF/BusyTable/IQ 副作用入口。该用例在修复前可编译并稳定 RED。
  task automatic run_v8d_int_ex_completion_kill_cut;
    reg [ROB_INDEX_W-1:0] branch_rob;
    reg [ROB_INDEX_W-1:0] younger_rob;
    reg [PHY_REG_ADDR_W-1:0] younger_pdest;
    reg [`XLEN-1:0] prf_before;
    reg [`XLEN-1:0] rob_data_before;
    begin
      reset_dut();
      set_dispatch0(32'h8000_6bc0, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_bht_idx = 10'h2e1;
      set_dispatch1(32'h8000_6bc4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h55);
      #1;
      tb_check1("v8d branch dispatch ready", dispatch0_ready, 1'b1);
      tb_check1("v8d younger ALU dispatch ready", dispatch1_ready, 1'b1);
      branch_rob = dut.dispatch0_rob_idx_w;
      younger_rob = dut.dispatch1_rob_idx_w;
      younger_pdest = dut.dispatch1_new_pdest_probe_w;
      prf_before = dut.u_phys_reg_file.regs_q[younger_pdest];
      rob_data_before = dut.u_dispatch_backend.u_rob.data_q[younger_rob];

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8d branch issues", dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("v8d younger ALU issues", dut.issue1_fire_w, 1'b1);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8d resolve valid", branch_resolve_valid, 1'b1);
      tb_check1("v8d resolve is mispredict", branch_resolve_mispredict, 1'b1);
      tb_check32("v8d resolve boundary identity",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}}, branch_rob});
      tb_check1("v8d boundary raw EX0 present", dut.ex0_valid_q, 1'b1);
      tb_check1("v8d younger raw EX1 present", dut.ex1_valid_q, 1'b1);
      tb_check1("v8d EX1 is strictly younger",
                ((younger_rob - dut.rob_head_idx_w) >
                 (branch_rob - dut.rob_head_idx_w)), 1'b1);
      tb_check32("v8d raw EX1 identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.ex1_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, younger_rob});
      tb_check1("v8d boundary completion survives", dut.wb0_valid_w, 1'b1);
      tb_check32("v8d boundary completion identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.wb0_rob_idx_w},
                 {{(32-ROB_INDEX_W){1'b0}}, branch_rob});
      tb_check1("v8d younger formal WB is cut", dut.wb1_valid_w, 1'b0);
      tb_check1("v8d younger PRF write is cut",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("v8d younger registered forwarding is cut",
                dut.ex1_registered_fwd_valid_w, 1'b0);
      tb_check1("v8d younger BusyTable wake is cut",
                dut.u_dispatch_backend.u_busy_table.wakeup1_valid_i, 1'b0);
      tb_check1("v8d younger integer-IQ wake is cut",
                dut.u_dispatch_backend.u_issue_queue.wakeup1_valid_i, 1'b0);
      tb_check1("v8d younger FP-IQ integer wake is cut",
                dut.u_fp_backend.int_wake1_valid_i, 1'b0);
      tb_check1("v8d younger ROB write is cut",
                dut.u_dispatch_backend.u_rob.wb1_valid_i, 1'b0);
      tb_check1("v8d younger public completion is cut", execute1_valid, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8d younger raw stage clears", dut.ex1_valid_q, 1'b0);
      tb_check64("v8d killed producer cannot alter PRF",
                 dut.u_phys_reg_file.regs_q[younger_pdest], prf_before);
      tb_check1("v8d killed producer cannot mark BusyTable ready",
                dut.u_dispatch_backend.u_busy_table.ready_q[younger_pdest],
                1'b0);
      tb_check1("v8d killed producer cannot mark ROB done",
                dut.u_dispatch_backend.u_rob.done_q[younger_rob], 1'b0);
      tb_check64("v8d killed producer cannot alter ROB data",
                 dut.u_dispatch_backend.u_rob.data_q[younger_rob],
                 rob_data_before);
      tb_check1("v8d killed completion has no delayed pulse",
                (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) ||
                (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)),
                1'b0);
      $display("[V8D-INT-EX-KILL-CUT] branch=%0d younger=%0d pdest=%0d raw-before=1 raw-after=%0b",
               branch_rob, younger_rob, younger_pdest, dut.ex1_valid_q);
      reset_dut();
    end
  endtask

  // 补充穷举只审 age/cut 组合函数；真实 root-cause 与 PRF 副作用仍由上面的
  // 无 force 用例承担。这里遍历全部 head/boundary/completion 4-bit 组合，
  // 专门防 raw-index 比较、equal 误杀和环回遗漏。
  task automatic run_v8d_int_ex_kill_age_matrix;
    integer head_i;
    integer boundary_i;
    integer completion_i;
    integer matrix_checks;
    integer matrix_failures;
    reg expected_kill;
    begin
      reset_dut();
      matrix_checks = 0;
      matrix_failures = 0;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.ex1_valid_q = 1'b1;
      force dut.ex0_valid_q = 1'b1;
      // v8d 只穷举 circular-age kill 函数。v8f 新增的 exact ProducerId
      // authorization 由独立反例测试覆盖；此处固定 open，避免仅 force raw
      // index 却未构造 ROB slot/generation 时把身份失配误记为年龄失败。
      force dut.ex0_producer_open_w = 1'b1;
      force dut.ex1_producer_open_w = 1'b1;
      for (head_i = 0; head_i < 16; head_i = head_i + 1) begin
        for (boundary_i = 0; boundary_i < 16;
             boundary_i = boundary_i + 1) begin
          for (completion_i = 0; completion_i < 16;
               completion_i = completion_i + 1) begin
            v8d_force_head_rob = head_i[ROB_INDEX_W-1:0];
            v8d_force_boundary_rob = boundary_i[ROB_INDEX_W-1:0];
            v8d_force_completion_rob = completion_i[ROB_INDEX_W-1:0];
            v8d_force_ex0_pid =
                {{PRODUCER_GEN_W{1'b0}}, v8d_force_completion_rob};
            v8d_force_ex1_pid =
                {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1,
                 v8d_force_completion_rob};
            // Icarus procedural force snapshots its RHS.  Re-issue the
            // variable-dependent forces for every matrix point so the test
            // really traverses all 4096 age tuples instead of one frozen row.
            force dut.rob_head_idx_w = v8d_force_head_rob;
            force dut.branch_resolve_rob_idx_o = v8d_force_boundary_rob;
            force dut.ex0_rob_idx_q = v8d_force_completion_rob;
            force dut.ex1_rob_idx_q = v8d_force_completion_rob;
            force dut.ex0_producer_id_q = v8d_force_ex0_pid;
            force dut.ex1_producer_id_q = v8d_force_ex1_pid;
            #1;
            expected_kill =
                ((v8d_force_completion_rob - v8d_force_head_rob) >
                 (v8d_force_boundary_rob - v8d_force_head_rob));
            matrix_checks = matrix_checks + 2;
            if ((dut.ex0_kill_now_w !== expected_kill) ||
                (dut.ex0_wb_valid_w !== !expected_kill))
              matrix_failures = matrix_failures + 1;
            if ((dut.ex1_kill_now_w !== expected_kill) ||
                (dut.ex1_wb_valid_w !== !expected_kill))
              matrix_failures = matrix_failures + 1;
            release dut.rob_head_idx_w;
            release dut.branch_resolve_rob_idx_o;
            release dut.ex0_rob_idx_q;
            release dut.ex1_rob_idx_q;
            release dut.ex0_producer_id_q;
            release dut.ex1_producer_id_q;
          end
        end
      end
      release dut.branch_resolve_mispredict_w;
      release dut.ex0_valid_q;
      release dut.ex1_valid_q;
      release dut.ex0_producer_open_w;
      release dut.ex1_producer_open_w;
      tb_check32("v8d exhaustive circular-age failures",
                 matrix_failures, 32'd0);
      tb_check32("v8d exhaustive circular-age checks",
                 matrix_checks, 32'd8192);
      $display("[V8D-INT-EX-KILL-AGE] checks=%0d failures=%0d",
               matrix_checks, matrix_failures);

      // 一个 strictly-younger raw EX0 不得继续占 completion slot；已存活的
      // older MulDiv response 必须沿既有优先级落到 WB0，不能被 kill 连带饿死。
      v8d_force_head_rob = 4'd8;
      v8d_force_boundary_rob = 4'd9;
      v8d_force_completion_rob = 4'd10;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.rob_head_idx_w = v8d_force_head_rob;
      force dut.branch_resolve_rob_idx_o = v8d_force_boundary_rob;
      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_rob_idx_q = v8d_force_completion_rob;
      v8d_force_ex0_pid =
          {{PRODUCER_GEN_W{1'b0}}, v8d_force_completion_rob};
      force dut.ex0_producer_id_q = v8d_force_ex0_pid;
      force dut.ex1_valid_q = 1'b0;
      force dut.ex0_producer_open_w = 1'b1;
      force dut.muldiv_resp_valid_w = 1'b1;
      v8d_force_longop_pid = 8;
      force dut.u_muldiv_unit.producer_id_q = v8d_force_longop_pid;
      force dut.muldiv_completion_rob_open_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd7;
      force dut.muldiv_resp_data_w = 64'h1234;
      #1;
      tb_check1("v8d killed EX0 frees slot", dut.ex0_kill_now_w, 1'b1);
      tb_check1("v8d older MulDiv takes freed WB0",
                dut.muldiv_rsp_to_wb0_w, 1'b1);
      tb_check1("v8d freed WB0 remains a live completion",
                dut.wb0_valid_w, 1'b1);
      tb_check32("v8d freed WB0 carries alternate identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.wb0_rob_idx_w}, 32'd8);
      release dut.branch_resolve_mispredict_w;
      release dut.rob_head_idx_w;
      release dut.branch_resolve_rob_idx_o;
      release dut.ex0_valid_q;
      release dut.ex0_rob_idx_q;
      release dut.ex0_producer_id_q;
      release dut.ex1_valid_q;
      release dut.ex0_producer_open_w;
      release dut.muldiv_resp_valid_w;
      release dut.u_muldiv_unit.producer_id_q;
      release dut.muldiv_completion_rob_open_w;
      release dut.muldiv_resp_pdest_w;
      release dut.muldiv_resp_data_w;

      // 当前真实可达拓扑是 boundary EX0 + strictly-younger EX1。补充锁定：
      // EX0 继续占 WB0 时，被杀 EX1 必须释放 WB1 给更老的 long-op completion。
      v8d_force_head_rob = 4'd14;
      v8d_force_boundary_rob = 4'd15;
      v8d_force_completion_rob = 4'd0;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.rob_head_idx_w = v8d_force_head_rob;
      force dut.branch_resolve_rob_idx_o = v8d_force_boundary_rob;
      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_rob_idx_q = v8d_force_boundary_rob;
      force dut.ex1_valid_q = 1'b1;
      force dut.ex1_rob_idx_q = v8d_force_completion_rob;
      v8d_force_ex0_pid =
          {{PRODUCER_GEN_W{1'b0}}, v8d_force_boundary_rob};
      v8d_force_ex1_pid =
          {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1,
           v8d_force_completion_rob};
      force dut.ex0_producer_id_q = v8d_force_ex0_pid;
      force dut.ex1_producer_id_q = v8d_force_ex1_pid;
      force dut.ex0_producer_open_w = 1'b1;
      force dut.ex1_producer_open_w = 1'b1;
      force dut.muldiv_resp_valid_w = 1'b1;
      v8d_force_longop_pid =
          {{PRODUCER_GEN_W{1'b0}}, v8d_force_head_rob};
      force dut.u_muldiv_unit.producer_id_q = v8d_force_longop_pid;
      force dut.muldiv_completion_rob_open_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd11;
      force dut.muldiv_resp_data_w = 64'h5678;
      #1;
      tb_check1("v8d boundary EX0 survives", dut.ex0_wb_valid_w, 1'b1);
      tb_check1("v8d reachable younger EX1 is killed",
                dut.ex1_kill_now_w, 1'b1);
      tb_check1("v8d killed EX1 frees WB1",
                dut.muldiv_rsp_to_wb1_w, 1'b1);
      tb_check32("v8d freed WB1 carries older alternate identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.wb1_rob_idx_w}, 32'd14);
      release dut.branch_resolve_mispredict_w;
      release dut.rob_head_idx_w;
      release dut.branch_resolve_rob_idx_o;
      release dut.ex0_valid_q;
      release dut.ex0_rob_idx_q;
      release dut.ex0_producer_id_q;
      release dut.ex1_valid_q;
      release dut.ex1_rob_idx_q;
      release dut.ex1_producer_id_q;
      release dut.ex0_producer_open_w;
      release dut.ex1_producer_open_w;
      release dut.muldiv_resp_valid_w;
      release dut.u_muldiv_unit.producer_id_q;
      release dut.muldiv_completion_rob_open_w;
      release dut.muldiv_resp_pdest_w;
      release dut.muldiv_resp_data_w;
      reset_dut();
    end
  endtask

  // T3S：lane0 memory reservation 必须是严格 non-fallthrough 边界。
  // bridge backpressure 时 reservation payload 保持，IQ raw lane0 不得借
  // 同拍 down-ready replacement 离队；flush 必须在产生副作用前清空。
  task automatic run_t3s_mem_issue_reservation_contract;
    reg [`XLEN-1:0] held_pc;
    reg [`XLEN-1:0] held_imm;
    reg [`CTRL_BUS_W-1:0] held_ctrl;
    reg [ROB_INDEX_W-1:0] held_rob;
    reg [ROB_INDEX_W-1:0] younger_rob;
    integer hold_cycles;
    integer younger_fire_count;
    integer younger_commit_count;
    integer younger_wb_count;
    integer observe_cycles;
    begin
      reset_dut();
      younger_fire_count = 0;
      younger_commit_count = 0;
      younger_wb_count = 0;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6c00,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0310);
      #1;
      tb_check1("T3S hold seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S hold seed capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check1("T3S hold seed no early request", mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3S hold reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T3S hold request valid under bridge stall",
                mem_req_valid, 1'b1);
      tb_check1("T3S occupied reservation freezes IQ lane0",
                dut.iq_issue0_ready_w, 1'b0);
      tb_check32("T3S held request address", mem_req_addr[31:0],
                 32'h8000_0310);
      held_pc = dut.mem_issue_res_pc_q;
      held_imm = dut.mem_issue_res_imm_q;
      held_ctrl = dut.mem_issue_res_ctrl_q;
      held_rob = dut.mem_issue_res_rob_idx_q;

      // younger simple 可进入 IQ，但 reservation 占用期间 raw lane0 不得 pop。
      set_dispatch0(32'h8000_6c04,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'd9);
      #1;
      tb_check1("T3S younger dispatch while reservation held",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3S younger enters IQ while held",
                 {28'b0, issue_count}, 32'd1);
      // T3V：resident memory reservation 是虚拟 lane0 owner。IQ 的 raw lane0
      // 必须保持安静，但 oldest-ready simple integer 可从真实 lane1 前进。
      tb_check1("T3V held memory excludes raw IQ lane0 owner",
                dut.iq_issue0_valid_w, 1'b0);
      tb_check1("T3V held memory promotes younger simple to lane1",
                dut.issue1_valid_w, 1'b1);
      tb_check1("T3V promoted younger lane1 is fireable",
                dut.issue1_fire_w, 1'b1);
      tb_check32("T3V promoted younger lane1 keeps PC",
                 dut.issue1_pc_w[31:0], 32'h8000_6c04);
      tb_check64("T3V promoted younger lane1 computes nine",
                 dut.issue1_alu_result_w, 64'd9);
      younger_rob = dut.issue1_rob_idx_w;
      tb_check64("T3V dedicated memory AGU ignores lane1 ALU",
                 dut.mem_issue_res_eff_addr_w, 64'h8000_0310);
      for (hold_cycles = 0; hold_cycles < 3;
           hold_cycles = hold_cycles + 1) begin
        tb_check1("T3S stalled reservation remains valid",
                  dut.mem_issue_res_valid_q, 1'b1);
        tb_check1("T3S stalled reservation keeps raw IQ lane0 frozen",
                  dut.iq_issue0_ready_w, 1'b0);
        tb_check64("T3S stalled reservation PC stable",
                   dut.mem_issue_res_pc_q, held_pc);
        tb_check64("T3S stalled reservation imm stable",
                   dut.mem_issue_res_imm_q, held_imm);
        tb_check32("T3S stalled reservation ROB stable",
                   {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                   {{(32-ROB_INDEX_W){1'b0}}, held_rob});
        tb_check64("T3V stalled request remains reservation AGU owned",
                   mem_req_addr, 64'h8000_0310);
        if (dut.mem_issue_res_ctrl_q !== held_ctrl) begin
          $display("[CHECK-FAIL] T3S stalled reservation ctrl changed got=0x%0h expected=0x%0h",
                   dut.mem_issue_res_ctrl_q, held_ctrl);
          tb_errors = tb_errors + 1;
        end
        if (dut.issue0_fire_w &&
            (dut.issue0_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        if (dut.issue1_fire_w &&
            (dut.issue1_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        `TB_TICK(clk);
        #1;
        if (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V promoted younger WB0 data", dut.wb0_data_w, 64'd9);
        end
        if (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V promoted younger WB1 data", dut.wb1_data_w, 64'd9);
        end
        tb_check1("T3V younger WB cannot pass older load",
                  commit0_valid || commit1_valid, 1'b0);
      end
      tb_check32("T3V promoted younger leaves IQ while held",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("T3V raw IQ lane0 remains quiet after promotion",
                dut.iq_issue0_valid_w, 1'b0);
      tb_check1("T3V lane1 does not replay promoted younger",
                dut.issue1_valid_w, 1'b0);
      tb_check32("T3V promoted younger writes back exactly once while held",
                 younger_wb_count, 32'd1);

      mem_req_ready = 1'b1;
      #1;
      tb_check1("T3S held request becomes fireable", mem_req_valid, 1'b1);
      tb_check1("T3V reservation owns MIQ push", dut.push_issue0_w, 1'b1);
      tb_check32("T3V MIQ metadata uses captured ROB",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, held_rob});
      tb_check64("T3V MIQ address uses dedicated AGU",
                 dut.miq_push_addr_w, 64'h8000_0310);
      tb_check1("T3V memory consume excludes generic issue0 fire",
                dut.issue0_fire_w, 1'b0);
      tb_check1("T3V memory consume has no younger lane1 replay",
                dut.issue1_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3S consumed reservation clears",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("T3S no same-cycle full-pop refill",
                dut.mem_issue_res_capture_w, 1'b0);
      // younger 已在 reservation hold 窗口从 lane1 exactly-once 执行；station
      // 释放后不能在 lane0/lane1 重新出现，也不能越过未完成的 older load 提交。
      if (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) begin
        younger_wb_count = younger_wb_count + 1;
        tb_check64("T3V no duplicate younger WB0 after release",
                   dut.wb0_data_w, 64'd9);
      end
      if (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)) begin
        younger_wb_count = younger_wb_count + 1;
        tb_check64("T3V no duplicate younger WB1 after release",
                   dut.wb1_data_w, 64'd9);
      end
      tb_check32("T3V released station keeps younger out of IQ",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("T3V released station has no lane0 replay",
                dut.issue0_valid_w || dut.issue0_fire_w, 1'b0);
      tb_check1("T3V released station has no lane1 replay",
                dut.issue1_valid_w || dut.issue1_fire_w, 1'b0);
      tb_check32("T3V younger WB remains exactly once after release",
                 younger_wb_count, 32'd1);
      tb_check1("T3V younger formal WB cannot pass older load",
                commit0_valid || commit1_valid, 1'b0);

      // Complete the older load only after the younger ALU has written back.
      // ROB ordering may expose the younger commit on either commit lane beside
      // the load, so count by PC rather than assuming a fixed lane.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0123_4567_89ab_cdef;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3V older load response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3V older response formal WB has no Q commit",
                commit0_valid || commit1_valid, 1'b0);
      if (commit0_valid && (commit0_pc[31:0] == 32'h8000_6c04)) begin
        younger_commit_count = younger_commit_count + 1;
        tb_check64("T3V younger commit0 data", commit0_data, 64'd9);
      end
      if (commit1_valid && (commit1_pc[31:0] == 32'h8000_6c04)) begin
        younger_commit_count = younger_commit_count + 1;
        tb_check64("T3V younger commit1 data", commit1_data, 64'd9);
      end
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      for (observe_cycles = 0; observe_cycles < 4;
           observe_cycles = observe_cycles + 1) begin
        if (dut.issue0_fire_w &&
            (dut.issue0_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        if (dut.issue1_fire_w &&
            (dut.issue1_pc_w[31:0] == 32'h8000_6c04))
          younger_fire_count = younger_fire_count + 1;
        if (dut.wb0_valid_w && (dut.wb0_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V younger later WB0 data", dut.wb0_data_w, 64'd9);
        end
        if (dut.wb1_valid_w && (dut.wb1_rob_idx_w == younger_rob)) begin
          younger_wb_count = younger_wb_count + 1;
          tb_check64("T3V younger later WB1 data", dut.wb1_data_w, 64'd9);
        end
        if (commit0_valid && (commit0_pc[31:0] == 32'h8000_6c04)) begin
          younger_commit_count = younger_commit_count + 1;
          tb_check64("T3V younger later commit0 data", commit0_data, 64'd9);
        end
        if (commit1_valid && (commit1_pc[31:0] == 32'h8000_6c04)) begin
          younger_commit_count = younger_commit_count + 1;
          tb_check64("T3V younger later commit1 data", commit1_data, 64'd9);
        end
        `TB_TICK(clk);
        #1;
      end
      tb_check32("T3V younger fires exactly once",
                 younger_fire_count, 32'd1);
      tb_check32("T3V younger writes back exactly once",
                 younger_wb_count, 32'd1);
      tb_check32("T3V younger commits exactly once",
                 younger_commit_count, 32'd1);
      tb_check32("T3V release sequence drains ROB",
                 {27'b0, rob_count}, 32'd0);
      $display("[T3V-MEM-RES-RELEASE] younger_fire=%0d younger_wb=%0d younger_commit=%0d",
               younger_fire_count, younger_wb_count, younger_commit_count);
      $display("[T3S-MEM-RES-HOLD] cycles=%0d rob=%0d addr=0x%08h younger_iq=%0d",
               hold_cycles, held_rob, held_imm[31:0], issue_count);

      // 独立复位后建立一个未请求 reservation，flush 必须无副作用清除。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6c10,
                    make_store_ctrl(`MEM_SIZE_WORD),
                    5'd0, 5'd0, 5'd0, 64'h8000_0320);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3S flush seed capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3S flush seed reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      mem_req_ready = 1'b1;
      #1;
      tb_check1("T3S flush clears reservation",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("T3S flush prevents request side effect", mem_req_valid, 1'b0);
      $display("[T3S-MEM-RES-FLUSH] valid=%0b req=%0b",
               dut.mem_issue_res_valid_q, mem_req_valid);
      reset_dut();
    end
  endtask

  // T3T 活性反例：younger memory 不得越过 IQ 中任何 older valid 项进入
  // reservation。这样 station 不会挡住稍后 wake 的 older branch，backend 也
  // 无需让 raw IQ 动态选择 resident execution owner。AMO/LR 仍叠加 ROB-head
  // admission，覆盖 older 已离开 IQ、但尚未完成退休的窗口。
  task automatic run_t3s_mem_issue_age_liveness;
    integer wait_cycles;
    begin
      // predicted-correct：branch 未 ready 时 younger load 必须留在 IQ；branch
      // fire 后 load 才可晋升并在下一沿进入 station。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6d00,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_6d04, make_branch_ctrl(`CMP_OP_EQ),
                    5'd5, 5'd0, 5'd0, 64'd8);
      dispatch1_pred_npc = 64'h8000_6d08;
      dispatch1_pred_taken = 1'b0;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("T3S age producer owns lane0",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d00);

      set_dispatch0(32'h8000_6d08,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0330);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3T younger load blocked by older branch",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check1("R3.2 older branch is the execution owner",
                dut.issue0_valid_w, 1'b1);
      tb_check32("T3T branch-load pair remains in IQ",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("T3T no premature station before branch",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("T3T older branch owns lane0 first",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d04);
      tb_check32("T3T execution mux selects older branch",
                 dut.issue0_pc_w[31:0], 32'h8000_6d04);
      tb_check1("T3T older branch sees shallow IQ ready",
                dut.iq_issue0_ready_w, 1'b1);
      tb_check1("T3T older branch fires",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("T3T branch cycle emits no memory request",
                mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T correct branch resolve emitted",
                branch_resolve_valid, 1'b1);
      tb_check1("T3T correct branch does not squash load",
                branch_resolve_mispredict, 1'b0);
      tb_check1("T3T load promotes only after branch pop",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check32("T3T promoted load identity",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d08);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T promoted load enters reservation",
                dut.mem_issue_res_valid_q, 1'b1);
      $display("[T3T-MEM-RES-OLDEST-CORRECT] branch=0x%08h resident=0x%08h",
               32'h8000_6d04, dut.mem_issue_res_pc_q[31:0]);

      // predicted-wrong：younger load 从未进入 station，resolve 直接从 IQ kill，
      // 当拍与下一拍都不得出现 ghost memory request。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6d20,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_6d24, make_branch_ctrl(`CMP_OP_EQ),
                    5'd5, 5'd0, 5'd0, 64'd8);
      dispatch1_pred_npc = 64'h8000_6d2c;
      dispatch1_pred_taken = 1'b1;
      `TB_TICK(clk);
      clear_dispatch();
      set_dispatch0(32'h8000_6d28,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h8000_0340);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3T wrong-path load remains blocked",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check1("T3T wrong-path branch fires first",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check1("T3T wrong-path load never entered station",
                dut.mem_issue_res_valid_q, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T mispredict resolve emitted",
                branch_resolve_mispredict, 1'b1);
      tb_check1("T3T mispredict masks younger execution",
                dut.issue0_valid_w, 1'b0);
      tb_check1("T3T mispredict exposes no ghost request",
                mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3T mispredict keeps station empty",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("T3T mispredict removes wrong-path IQ entry",
                 {28'b0, issue_count}, 32'd0);
      $display("[T3T-MEM-RES-OLDEST-MISPREDICT] valid=%0b req=%0b",
               dut.mem_issue_res_valid_q, mem_req_valid);

      // Exact LR contract：IQ oldest gate 先挡住 older branch，branch pop 后又由
      // AMO-head gate 等待退休边界；两层准入均不得 pop/capture LR。
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6d40,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'd1);
      set_dispatch1(32'h8000_6d44, make_branch_ctrl(`CMP_OP_EQ),
                    5'd5, 5'd0, 5'd0, 64'd8);
      dispatch1_pred_npc = 64'h8000_6d48;
      dispatch1_pred_taken = 1'b0;
      `TB_TICK(clk);
      clear_dispatch();
      set_dispatch0(32'h8000_6d48,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd7, 64'h8000_0350);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd7);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3T LR blocked behind older branch",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check32("T3T older branch owns lane0 before LR",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6d44);
      tb_check1("T3T older branch fires before LR",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      wait_cycles = 0;
      while (!dut.mem_issue_res_capture_w && (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("T3T LR eventually admitted at ROB head",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check1("T3T LR admission sees valid ROB head",
                dut.rob_head_valid_w, 1'b1);
      tb_check32("T3T LR raw ROB equals head",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.iq_issue0_rob_idx_w},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w});
      `TB_TICK(clk);
      #1;
      tb_check1("T3T head LR enters reservation",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check32("T3T resident LR remains ROB head",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w});
      $display("[T3T-MEM-RES-AMO-HEAD] wait=%0d rob=%0d",
               wait_cycles, dut.mem_issue_res_rob_idx_q);
      reset_dut();
    end
  endtask

  // T3V post-reservation buffer 也必须参加 selective ROB-walk kill。buffer
  // handoff 由合法的 older LEGACY LR pending + younger plain load 自然构造；只对白盒
  // delayed resolve pulse 做层次注入，以命中“buffer 已驻留但尚未 fire”的窗口。
  task automatic run_t3v_mem_buffer_selective_kill_contract;
    reg [ROB_INDEX_W-1:0] buffer_rob;
    integer quiet_cycles;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;

      // LR remains the intentional LEGACY singleton owner.  Plain loads no
      // longer become LEGACY merely because their VA resembles MMIO.
      set_dispatch0(32'h8000_6d60,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd10, 64'h0000_0200);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd10);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V buffer-kill seed capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill seed request visible", mem_req_valid, 1'b1);
      tb_check1("T3V buffer-kill seed is LEGACY push",
                dut.miq_push_valid_w &&
                (dut.miq_push_kind_w == 2'd3), 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill seed pending", dut.mem_pending_q, 1'b1);
      tb_check32("T3V buffer-kill seed occupies one MIQ entry",
                 {28'b0, dut.miq_count_w}, 32'd1);

      // Keep this correctly predicted branch in ROB as an older selective-kill
      // boundary.  commit_ready=0 prevents it from retiring before injection.
      set_dispatch0(32'h8000_6d64, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_taken = 1'b1;
      dispatch0_pred_npc = 64'h8000_6d6c;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V buffer-kill older branch fires",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      t3v_force_branch_rob = dut.issue0_rob_idx_w;
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill older branch resolves",
                branch_resolve_valid, 1'b1);
      tb_check1("T3V buffer-kill seed resolve is initially correct",
                branch_resolve_mispredict, 1'b0);
      `TB_TICK(clk);
      #1;

      // A younger plain store consumes its reservation into mem_buffer because
      // the older LEGACY request remains pending.  No bridge request fires.
      set_dispatch0(32'h8000_6d68,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h8000_03c0);
      dispatch0_inst = 32'h0000_3023;  // sd x0,0(x0)
      #1;
      buffer_rob = dut.dispatch0_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V buffer-kill younger capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill real buffer handoff",
                dut.issue0_mem_buffer_fire_w, 1'b1);
      tb_check1("T3V buffer-kill handoff has no request",
                dut.mem_req_fire_any_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V buffer-kill younger resident in buffer",
                dut.mem_buffer_valid_q, 1'b1);
      tb_check32("T3V buffer-kill buffer ROB identity",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_buffer_rob_idx_q},
                 {{(32-ROB_INDEX_W){1'b0}}, buffer_rob});
      tb_check64("T3V buffer-kill buffer address",
                 dut.mem_buffer_eff_addr_q, 64'h8000_03c0);
      tb_check1("T3V buffer-kill buffer still cannot request",
                dut.mem_buffer_req_valid_w, 1'b0);

      // Retire the old LEGACY response first, so the younger buffer has an
      // actually open request slot and bridge ready=1.  The delayed
      // mispredict below must still cut the killed request before grant; a
      // closed-slot test would only prove incidental blocking.
      // Hold request ready low on the old response edge so pop look-through
      // cannot hand the buffered request to MIQ before the kill window opens.
      mem_req_ready = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_cafe_babe;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3V buffer-kill old response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3V buffer-kill old response exact fire",
                dut.mem_rsp_fire_w, 1'b1);
      tb_check1("T3V buffer-kill old response pops MIQ",
                dut.miq_pop_w, 1'b1);
      tb_check1("T3V buffer-kill old response is final",
                dut.mem_rsp_final_fire_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      mem_req_ready = 1'b1;
      #1;
      tb_check32("T3V buffer-kill old MIQ drains",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("T3V buffer-kill request slot opens",
                dut.mem_buffer_req_valid_w, 1'b1);
      tb_check1("T3V buffer-kill would fire before resolve",
                dut.mem_buffer_req_fire_w, 1'b1);

      // Inject a delayed mispredict for the still-resident older branch.  This
      // is intentionally white-box only at the resolve boundary; ROB ages,
      // reservation->buffer handoff, and all memory ownership are real.
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      #1;
      tb_check1("T3V buffer-kill recognizes younger buffer",
                dut.mem_buffer_kill_w, 1'b1);
      tb_check1("T3V buffer-kill open-slot cannot fire",
                dut.mem_buffer_req_fire_w, 1'b0);
      tb_check1("T3V buffer-kill open-slot has no request",
                mem_req_valid, 1'b0);
      tb_check1("T3V buffer-kill injects no MIQ owner",
                dut.miq_push_valid_w, 1'b0);
      tb_check1("T3V buffer-kill emits local terminal",
                dut.mem_buffer_cancel_w, 1'b1);
      `TB_TICK(clk);
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      tb_check1("T3V buffer-kill clears younger buffer",
                dut.mem_buffer_valid_q, 1'b0);
      tb_check32("T3V buffer-kill leaves drained MIQ empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("T3V buffer-kill exposes no request after kill",
                mem_req_valid, 1'b0);

      commit_ready = 1'b1;
      #1;
      for (quiet_cycles = 0; quiet_cycles < 4;
           quiet_cycles = quiet_cycles + 1) begin
        tb_check1("T3V buffer-kill no ghost request", mem_req_valid, 1'b0);
        tb_check1("T3V buffer-kill no ghost MIQ push",
                  dut.miq_push_valid_w, 1'b0);
        tb_check1("T3V buffer-kill no ghost WB0",
                  !(dut.wb0_valid_w &&
                    (dut.wb0_rob_idx_w == buffer_rob)), 1'b1);
        tb_check1("T3V buffer-kill no ghost WB1",
                  !(dut.wb1_valid_w &&
                    (dut.wb1_rob_idx_w == buffer_rob)), 1'b1);
        tb_check1("T3V buffer-kill no ghost commit0",
                  !(commit0_valid &&
                    (commit0_pc[31:0] == 32'h8000_6d68)), 1'b1);
        tb_check1("T3V buffer-kill no ghost commit1",
                  !(commit1_valid &&
                    (commit1_pc[31:0] == 32'h8000_6d68)), 1'b1);
        `TB_TICK(clk);
        #1;
      end
      $display("[V8G-MEM-BUFFER-KILL-READY-CUT] open slot and ready cannot launch a younger-killed buffer PASS");
      $display("[T3V-MEM-BUFFER-KILL] boundary_rob=%0d killed_rob=%0d quiet_cycles=%0d",
               t3v_force_branch_rob, buffer_rob, quiet_cycles);
      reset_dut();
    end
  endtask

  task automatic seed_s2_g1_selective_kill_boundary;
    input [`XLEN-1:0] branch_pc;
    output [ROB_INDEX_W-1:0] boundary_rob;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(branch_pc, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_taken = 1'b1;
      dispatch0_pred_npc = branch_pc + 64'd8;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("S2-G1 boundary branch fires",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      boundary_rob = dut.issue0_rob_idx_w;
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 boundary branch resolves", branch_resolve_valid, 1'b1);
      tb_check1("S2-G1 boundary branch is initially correct",
                branch_resolve_mispredict, 1'b0);
      `TB_TICK(clk);
      #1;
    end
  endtask

  // S2-G1: same-cycle selective kill must drain the exact response and create
  // one accounting terminal, while suppressing every architectural side
  // effect even when both formal WB slots are unavailable.
  task automatic run_s2_g1_effective_kill_response_contract;
    reg [ROB_INDEX_W-1:0] boundary_rob;
    reg [4:0] owner_token;
    integer wait_cycles;
    begin
      seed_s2_g1_selective_kill_boundary(64'h8000_6e80,
                                         boundary_rob);
      set_dispatch0(64'h8000_6e88,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd18, 64'h8000_0500);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("S2-G1 killed LOAD capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 killed LOAD request fire",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check32("S2-G1 killed LOAD request kind",
                 {30'b0, dut.miq_push_kind_w}, 32'd0);
      `TB_TICK(clk);
      #1;
      tb_check32("S2-G1 killed LOAD MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      owner_token = dut.miq_head_owner_token_w;

      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      force dut.wb_slot_free_w = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1122_3344_5566_7788;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S2-G1 killed LOAD effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("S2-G1 killed LOAD drains without WB credit",
                mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 killed LOAD exact pop", dut.miq_pop_w, 1'b1);
      tb_check1("S2-G1 killed LOAD has no WB", dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 killed LOAD lane0 terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b1);
      tb_check32("S2-G1 killed LOAD terminal token",
                 {27'b0, dut.mem_terminal_ingress_token_w[4:0]},
                 {27'b0, owner_token});
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      release dut.wb_slot_free_w;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      tb_check32("S2-G1 killed LOAD MIQ drains",
                 {28'b0, dut.miq_count_w}, 32'd0);
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 killed LOAD owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("S2-G1 killed LOAD terminal queue drains",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);

      seed_s2_g1_selective_kill_boundary(64'h8000_6ea0,
                                         boundary_rob);
      set_dispatch0(64'h8000_6ea8,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h8000_0520);
      dispatch0_inst = 32'h0000_3023;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("S2-G1 killed PROBE capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 killed PROBE request fire",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check32("S2-G1 killed PROBE request kind",
                 {30'b0, dut.miq_push_kind_w}, 32'd1);
      `TB_TICK(clk);
      #1;
      owner_token = dut.miq_head_owner_token_w;

      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      force dut.wb_slot_free_w = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_9000_0520;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("S2-G1 killed PROBE effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("S2-G1 killed PROBE drains without WB credit",
                mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 killed PROBE exact pop", dut.miq_pop_w, 1'b1);
      tb_check1("S2-G1 killed PROBE has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 killed PROBE has no SQ fill",
                dut.sq_fill_valid_w, 1'b0);
      tb_check1("S2-G1 killed PROBE has no SQ terminal",
                dut.sq_probe_terminal_w, 1'b0);
      tb_check1("S2-G1 killed PROBE lane0 terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b1);
      tb_check32("S2-G1 killed PROBE terminal token",
                 {27'b0, dut.mem_terminal_ingress_token_w[4:0]},
                 {27'b0, owner_token});
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      release dut.wb_slot_free_w;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 killed PROBE owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("S2-G1 killed PROBE terminal queue drains",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
      $display("[T4S-EFFKILL-RSP] LOAD+PROBE exact-pop/terminal once, WB/SQ side effects zero PASS");
      reset_dut();
    end
  endtask

  // v8w: the bridge's exact active-owner drop is the MIQ terminal for a
  // selectively recovered LOAD.  Each bank must pop the same 9-bit owner
  // tuple on the drop edge; the tagged collector then retires the tracker
  // lease without any architectural completion.
  task automatic run_v8w_miq_drop_recovery_contract;
    reg [ROB_INDEX_W-1:0] boundary_rob;
    reg [1:0] owner_kind;
    reg [4:0] owner_token;
    reg [1:0] owner_epoch;
    reg [`XLEN-1:0] owner_tval;
    integer wait_cycles;
    begin
      seed_s2_g1_selective_kill_boundary(64'h8000_6ec0,
                                         boundary_rob);
      set_dispatch0(64'h8000_6ec8,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd19, 64'h8000_0540);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8W bank0 LOAD capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8W bank0 LOAD request fire",
                dut.mem_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8W bank0 LOAD MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("V9Y bank0 active holder is not terminalized",
                dut.mem_owner_terminalized_o, 1'b0);
      owner_kind = dut.miq_head_owner_kind_w;
      owner_token = dut.miq_head_owner_token_w;
      owner_epoch = dut.miq_head_mmu_epoch_w;
      owner_tval = dut.miq_head_fault_tval_w;

      // A raw bridge terminal is not itself queue-pop authority.  Probe the
      // three independent guards combinationally, restoring each malformed
      // input before an edge so the collector is not asked to retire an
      // intentionally illegal terminal.
      tb_mem_drop0_valid = 1'b1;
      tb_mem_drop0_owner_kind = owner_kind;
      tb_mem_drop0_owner_token = owner_token;
      tb_mem_drop0_mmu_epoch = owner_epoch;
      tb_mem_drop0_fault_tval = owner_tval;
      #1;
      tb_check1("V8W bank0 live head blocks raw exact drop pop",
                dut.miq_drop0_pop_w, 1'b0);
      tb_mem_drop0_valid = 1'b0;
      #1;

      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      tb_mem_drop0_valid = 1'b1;
      tb_mem_drop0_owner_token = owner_token ^ 5'b00001;
      #1;
      tb_check1("V8W bank0 killed head blocks wrong-tuple drop pop",
                dut.miq_drop0_pop_w, 1'b0);
      tb_mem_drop0_valid = 1'b0;
      tb_mem_drop0_owner_token = owner_token;
      tb_mem_drop0_mmu_epoch = owner_epoch ^ 2'b01;
      tb_mem_drop0_valid = 1'b1;
      #1;
      tb_check1("V9Y wrong-epoch raw ingress is not accepted",
                dut.mem_terminal_ingress_accept_w[2], 1'b0);
      tb_check1("V9Y wrong-epoch holder remains unterminated",
                dut.mem_owner_terminalized_o, 1'b0);
      tb_mem_drop0_valid = 1'b0;
      tb_mem_drop0_mmu_epoch = owner_epoch;
      tb_mem1_drop0_valid = 1'b1;
      tb_mem1_drop0_owner_kind = owner_kind;
      tb_mem1_drop0_owner_token = owner_token;
      tb_mem1_drop0_mmu_epoch = owner_epoch;
      tb_mem1_drop0_fault_tval = owner_tval;
      tb_mem_drop0_valid = 1'b1;
      #1;
      tb_check1("V9Y duplicate lane2 ingress is not accepted",
                dut.mem_terminal_ingress_accept_w[2], 1'b0);
      tb_check1("V9Y duplicate lane4 ingress is not accepted",
                dut.mem_terminal_ingress_accept_w[4], 1'b0);
      tb_check1("V9Y duplicate raw ingress leaves holder unterminated",
                dut.mem_owner_terminalized_o, 1'b0);
      tb_mem_drop0_valid = 1'b0;
      tb_mem1_drop0_valid = 1'b0;
      #1;
      $display("[V9Y-ACCEPTED-TRANSFER-NEGATIVE] tuple=0 duplicate=0 terminalized=0 PASS");
      force dut.miq_head_tracker_exact_w = 1'b0;
      tb_mem_drop0_valid = 1'b1;
      #1;
      tb_check1("V8W bank0 killed head blocks tracker-mismatch drop pop",
                dut.miq_drop0_pop_w, 1'b0);
      tb_mem_drop0_valid = 1'b0;
      release dut.miq_head_tracker_exact_w;
      #1;
      tb_mem_drop0_valid = 1'b1;
      #1;
      tb_check1("V8W bank0 LOAD effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("V8W bank0 expected kill reaches bridge",
                mem_expected_effective_killed, 1'b1);
      tb_check1("V8W bank0 exact drop selects MIQ pop",
                dut.miq_queue_pop_valid_w, 1'b1);
      tb_check1("V8W bank0 exact drop matches MIQ head",
                dut.miq_pop_owner_match_w, 1'b1);
      tb_check1("V8W bank0 exact drop enters collector once",
                dut.mem_terminal_ingress_valid_w[2], 1'b1);
      tb_check1("V9Y bank0 exact drop is same-edge terminalized",
                dut.mem_owner_terminalized_o, 1'b1);
      tb_check1("V8W bank0 exact drop has no memory WB",
                dut.mem_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      tb_mem_drop0_valid = 1'b0;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      commit_ready = 1'b1;
      #1;
      tb_check32("V8W bank0 exact drop drains MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("V9Y bank0 collector-pending owner is terminalized",
                dut.mem_owner_terminalized_o, 1'b1);
      tb_check1("V9Y bank0 collector-pending is not full idle",
                dut.mem_idle_o, 1'b0);
      wait_cycles = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              (rob_count != 0)) && (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check32("V8W bank0 exact drop frees owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("V8W bank0 exact drop drains collector",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
      tb_check1("V8W bank0 exact drop reaches memory idle",
                dut.mem_idle_o, 1'b1);
      tb_check1("V9Y bank0 full idle remains terminalized",
                dut.mem_owner_terminalized_o, 1'b1);

      seed_s2_g1_selective_kill_boundary(64'h8000_6ee0,
                                         boundary_rob);
      set_dispatch0(64'h8000_6ee8,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd20, 64'h8000_0548);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8W bank1 LOAD capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8W bank1 LOAD request fire",
                dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8W bank1 LOAD MIQ resident",
                 {28'b0, dut.miq1_count_w}, 32'd1);
      tb_check1("V9Y bank1 active holder is not terminalized",
                dut.mem_owner_terminalized_o, 1'b0);
      owner_kind = dut.miq1_head_owner_kind_w;
      owner_token = dut.miq1_head_owner_token_w;
      owner_epoch = dut.miq1_head_mmu_epoch_w;
      owner_tval = dut.miq1_head_fault_tval_w;

      tb_mem1_drop0_valid = 1'b1;
      tb_mem1_drop0_owner_kind = owner_kind;
      tb_mem1_drop0_owner_token = owner_token;
      tb_mem1_drop0_mmu_epoch = owner_epoch;
      tb_mem1_drop0_fault_tval = owner_tval;
      #1;
      tb_check1("V8W bank1 live head blocks raw exact drop pop",
                dut.miq1_drop0_pop_w, 1'b0);
      tb_mem1_drop0_valid = 1'b0;
      #1;

      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      tb_mem1_drop0_valid = 1'b1;
      tb_mem1_drop0_owner_token = owner_token ^ 5'b00001;
      #1;
      tb_check1("V8W bank1 killed head blocks wrong-tuple drop pop",
                dut.miq1_drop0_pop_w, 1'b0);
      tb_mem1_drop0_valid = 1'b0;
      tb_mem1_drop0_owner_token = owner_token;
      force dut.miq1_head_tracker_exact_w = 1'b0;
      tb_mem1_drop0_valid = 1'b1;
      #1;
      tb_check1("V8W bank1 killed head blocks tracker-mismatch drop pop",
                dut.miq1_drop0_pop_w, 1'b0);
      tb_mem1_drop0_valid = 1'b0;
      release dut.miq1_head_tracker_exact_w;
      #1;
      tb_mem1_drop0_valid = 1'b1;
      #1;
      tb_check1("V8W bank1 LOAD effective kill",
                dut.miq1_head_effective_killed_w, 1'b1);
      tb_check1("V8W bank1 expected kill reaches bridge",
                mem1_expected_effective_killed, 1'b1);
      tb_check1("V8W bank1 exact drop selects MIQ pop",
                dut.miq1_queue_pop_valid_w, 1'b1);
      tb_check1("V8W bank1 exact drop matches MIQ head",
                dut.miq1_pop_owner_match_w, 1'b1);
      tb_check1("V8W bank1 exact drop enters collector once",
                dut.mem_terminal_ingress_valid_w[4], 1'b1);
      tb_check1("V9Y bank1 exact drop is same-edge terminalized",
                dut.mem_owner_terminalized_o, 1'b1);
      tb_check1("V8W bank1 exact drop has no memory WB",
                dut.mem1_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      tb_mem1_drop0_valid = 1'b0;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      commit_ready = 1'b1;
      #1;
      tb_check32("V8W bank1 exact drop drains MIQ",
                 {28'b0, dut.miq1_count_w}, 32'd0);
      wait_cycles = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              (rob_count != 0)) && (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check32("V8W bank1 exact drop frees owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("V8W bank1 exact drop drains collector",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
      tb_check1("V8W bank1 exact drop reaches memory idle",
                dut.mem_idle_o, 1'b1);
      tb_check1("V9Y bank1 full idle remains terminalized",
                dut.mem_owner_terminalized_o, 1'b1);
      $display("[V8W-MIQ-DROP-RECOVERY] bank0+bank1 exact drop/pop/terminal/idle PASS");
      $display("[V9Y-MEM-TERMINAL-PHASE] active=0 transfer=1 pending-only=1 full-idle=1 lane2=1 lane4=1 PASS");
      reset_dut();
    end
  endtask

  // V11I: close the post-LQ-clear terminal lifecycle at the real parent
  // wiring.  Thirty-two completed LOAD owners advance the production tracker
  // cursor through every token.  The next LOAD reuses the first token with a
  // different full ProducerId and remains resident under request
  // backpressure; every old terminal source must stay quiet.
  task automatic v11i_complete_response_load_owner;
    input integer owner_sequence;
    output [PRODUCER_ID_W-1:0] owner_pid;
    output [4:0] owner_token;
    integer wait_cycles;
    begin
      mem_translate_active = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(64'h0000_0000_8001_0000 +
                    (owner_sequence * 8),
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd1,
                    64'h0000_0000_0000_2000 +
                    (owner_sequence * 8));
      dispatch0_inst = 32'h0000_3083;
      set_dispatch1(64'h0000_0000_8001_0004 +
                    (owner_sequence * 8),
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd0, 64'd0);
      dispatch1_inst = 32'h0000_0013;
      #1;
      if (!dispatch0_ready || !dispatch1_ready) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d dispatch_ready=%b%b @%0t",
                 owner_sequence, dispatch1_ready, dispatch0_ready, $time);
        $fatal(1);
      end
      owner_pid = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (!dut.mem_issue_res_capture_w) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d no reservation capture @%0t",
                 owner_sequence, $time);
        $fatal(1);
      end
      owner_token = dut.mem_owner_alloc0_token_w;
      if (owner_token != (owner_sequence % 32)) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d token=%0d expected=%0d @%0t",
                 owner_sequence, owner_token, owner_sequence % 32, $time);
        $fatal(1);
      end

      `TB_TICK(clk);
      #1;
      if (!dut.mem_issue_res_valid_q ||
          dut.issue0_mem_exception_w ||
          !mem_req_valid || !dut.mem_req_fire_any_w) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d token=%0d valid=%0b exception=%0b req_valid=%0b req_fire=%0b @%0t",
                 owner_sequence, owner_token,
                 dut.mem_issue_res_valid_q,
                 dut.issue0_mem_exception_w,
                 mem_req_valid, dut.mem_req_fire_any_w, $time);
        $fatal(1);
      end
      `TB_TICK(clk);
      #1;
      if (!dut.miq_head_valid_w ||
          (dut.miq_head_owner_token_w != owner_token)) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d token=%0d miq_valid=%0b miq_token=%0d @%0t",
                 owner_sequence, owner_token, dut.miq_head_valid_w,
                 dut.miq_head_owner_token_w, $time);
        $fatal(1);
      end

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_5100_0000 + owner_sequence;
      mem_rsp_error = 1'b0;
      #1;
      if (!mem_rsp_ready ||
          !dut.mem_terminal_ingress_valid_w[0] ||
          !dut.mem_terminal_ingress_accept_w[0]) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d token=%0d rsp_ready=%0b ingress0=%0b accept0=%0b @%0t",
                 owner_sequence, owner_token, mem_rsp_ready,
                 dut.mem_terminal_ingress_valid_w[0],
                 dut.mem_terminal_ingress_accept_w[0], $time);
        $fatal(1);
      end
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      wait_cycles = 0;
      while (((rob_count != 0) || (issue_count != 0) ||
              (dut.lq_count_w != 0) ||
              (dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              dut.mem_issue_res_valid_q || dut.ex0_valid_q ||
              dut.ex1_valid_q) &&
             (wait_cycles < 24)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      if ((rob_count != 0) || (issue_count != 0) ||
          (dut.lq_count_w != 0) ||
          (dut.mem_owner_live_count_w != 0) ||
          (dut.mem_terminal_pending_count_w != 0) ||
          dut.mem_issue_res_valid_q || dut.ex0_valid_q ||
          dut.ex1_valid_q) begin
        $display("[V11I-OWNER-CYCLE][FAIL] seq=%0d drain_timeout rob=%0d iq=%0d lq=%0d live=%0d pending=%0d res=%0b ex=%0b%0b @%0t",
                 owner_sequence, rob_count, issue_count, dut.lq_count_w,
                 dut.mem_owner_live_count_w,
                 dut.mem_terminal_pending_count_w,
                 dut.mem_issue_res_valid_q, dut.ex1_valid_q,
                 dut.ex0_valid_q, $time);
        $fatal(1);
      end
    end
  endtask

  task automatic run_v11i_terminal_lifecycle_after_lq_clear;
    reg [PRODUCER_ID_W-1:0] old_pid;
    reg [PRODUCER_ID_W-1:0] filler_pid;
    reg [PRODUCER_ID_W-1:0] new_pid;
    reg [4:0] old_token;
    reg [4:0] filler_token;
    reg [4:0] new_token;
    reg new_lq_found;
    reg new_lq_terminal_seen;
    integer owner_sequence;
    integer quiet_cycle;
    integer wait_cycles;
    integer lq_entry;
    begin
      reset_dut();
      commit_ready = 1'b1;

      old_pid = {PRODUCER_ID_W{1'b0}};
      old_token = 5'd0;
      for (owner_sequence = 0; owner_sequence < 32;
           owner_sequence = owner_sequence + 1) begin
        v11i_complete_response_load_owner(owner_sequence,
                                           filler_pid, filler_token);
        if (owner_sequence == 0) begin
          old_pid = filler_pid;
          old_token = filler_token;
        end
      end

      mem_translate_active = 1'b0;
      mem_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8001_1000,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd2,
                    64'h0000_0000_0000_1800);
      dispatch0_inst = 32'h0000_3103;
      set_dispatch1(64'h0000_0000_8001_1004,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd0, 64'd0);
      dispatch1_inst = 32'h0000_0013;
      #1;
      if (!dispatch0_ready || !dispatch1_ready) begin
        $display("[V11I-TOKEN-WRAP][FAIL] reuse dispatch was not accepted @%0t",
                 $time);
        $fatal(1);
      end
      new_pid = dut.u_dispatch_backend.rob_dispatch0_producer_id_w;
      if (new_pid == old_pid) begin
        $display("[V11I-TOKEN-WRAP][FAIL] old/new full PID aliased old=%h new=%h @%0t",
                 old_pid, new_pid, $time);
        $fatal(1);
      end
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (!dut.mem_issue_res_capture_w) begin
        $display("[V11I-TOKEN-WRAP][FAIL] reuse reservation did not capture @%0t",
                 $time);
        $fatal(1);
      end
      new_token = dut.mem_owner_alloc0_token_w;
      if (new_token != old_token) begin
        $display("[V11I-TOKEN-WRAP][FAIL] cursor did not reuse token old=%0d new=%0d @%0t",
                 old_token, new_token, $time);
        $fatal(1);
      end
      `TB_TICK(clk);
      #1;

      new_lq_found = 1'b0;
      new_lq_terminal_seen = 1'b0;
      for (lq_entry = 0; lq_entry < V11I_LQ_ENTRY_N;
           lq_entry = lq_entry + 1) begin
        if (dut.u_load_queue.valid_q[lq_entry] &&
            (dut.u_load_queue.producer_id_q[lq_entry] == new_pid)) begin
          new_lq_found = 1'b1;
          new_lq_terminal_seen =
              dut.u_load_queue.terminal_seen_q[lq_entry];
        end
      end
      if (!dut.mem_issue_res_valid_q ||
          dut.issue0_mem_exception_w || dut.mem_req_fire_any_w ||
          !new_lq_found || new_lq_terminal_seen ||
          !dut.mem_owner_live_mask_w[new_token] ||
          (dut.mem_owner_producer_id_table_w[
              new_token*PRODUCER_ID_W +: PRODUCER_ID_W] != new_pid)) begin
        $display("[V11I-TOKEN-WRAP][FAIL] new holder state res=%0b exception=%0b req_fire=%0b lq_found=%0b terminal_seen=%0b token_live=%0b table_pid=%h expected_pid=%h @%0t",
                 dut.mem_issue_res_valid_q,
                 dut.issue0_mem_exception_w,
                 dut.mem_req_fire_any_w,
                 new_lq_found, new_lq_terminal_seen,
                 dut.mem_owner_live_mask_w[new_token],
                 dut.mem_owner_producer_id_table_w[
                     new_token*PRODUCER_ID_W +: PRODUCER_ID_W],
                 new_pid, $time);
        $fatal(1);
      end

`ifdef V11I_STALE_TERMINAL_MUTATION
      // The compile-success RTL variant holds the first token-0 tuple, waits
      // for the tracker cursor to wrap to a different full ProducerId, then
      // raises the delayed old response tuple on lane0 in the following cycle.
      `TB_TICK(clk);
      #1;
      if (!dut.mem_terminal_ingress_valid_w[0] ||
          !dut.mem_terminal_ingress_accept_w[0]) begin
        $display("[V11I-STALE-SOURCE-ACTIVATION][FAIL] old_pid=%h new_pid=%h token=%0d ingress=%0b accept=%0b @%0t",
                 old_pid, new_pid, new_token,
                 dut.mem_terminal_ingress_valid_w[0],
                 dut.mem_terminal_ingress_accept_w[0], $time);
        $fatal(1);
      end
      $display("[V11I-STALE-SOURCE-ACTIVE] old_pid=%h new_pid=%h token=%0d lane=0 @%0t",
               old_pid, new_pid, new_token, $time);
`ifdef OOO_ASSERT
      // The mutated pulse is accepted on this edge.  The real B reservation
      // remains resident; the next edge must therefore trip the production
      // holder-after-terminal assertion.
      `TB_TICK(clk);
      #1;
      `TB_TICK(clk);
      #1;
      $display("[V11I-HOLDER-ASSERTION-ESCAPED][FAIL] old_pid=%h new_pid=%h token=%0d @%0t",
               old_pid, new_pid, new_token, $time);
      $fatal(1);
`else
      // Accept into the collector, then let its dequeue/free edge update both
      // tracker and LQ.  The independent raw-Q observation proves that the old
      // tuple was interpreted as the new full ProducerId; this is harmful ABA,
      // not a harmless duplicate that may be filtered.
      `TB_TICK(clk);
      #1;
      `TB_TICK(clk);
      #1;
      `TB_TICK(clk);
      #1;
      new_lq_found = 1'b0;
      new_lq_terminal_seen = 1'b0;
      for (lq_entry = 0; lq_entry < V11I_LQ_ENTRY_N;
           lq_entry = lq_entry + 1) begin
        if (dut.u_load_queue.valid_q[lq_entry] &&
            (dut.u_load_queue.producer_id_q[lq_entry] == new_pid)) begin
          new_lq_found = 1'b1;
          new_lq_terminal_seen =
              dut.u_load_queue.terminal_seen_q[lq_entry];
        end
      end
      if (!new_lq_found || !new_lq_terminal_seen ||
          dut.mem_owner_live_mask_w[new_token] ||
          !dut.mem_issue_res_valid_q) begin
        $display("[V11I-LATE-TUPLE-OBSERVATION][FAIL] old_pid=%h new_pid=%h token=%0d lq_found=%0b terminal_seen=%0b tracker_live=%0b holder_live=%0b @%0t",
                 old_pid, new_pid, new_token, new_lq_found,
                 new_lq_terminal_seen,
                 dut.mem_owner_live_mask_w[new_token],
                 dut.mem_issue_res_valid_q, $time);
        $fatal(1);
      end
      $display("[V11I-LATE-TUPLE-ABA][FAIL] old_pid=%h new_pid=%h token=%0d lane=0 accepted=1 tracker_freed_new_owner=1 lq_terminal_seen_new_pid=1 @%0t",
               old_pid, new_pid, new_token, $time);
      $fatal(1);
`endif
`else
      for (quiet_cycle = 0; quiet_cycle < 3;
           quiet_cycle = quiet_cycle + 1) begin
        new_lq_found = 1'b0;
        new_lq_terminal_seen = 1'b0;
        for (lq_entry = 0; lq_entry < V11I_LQ_ENTRY_N;
             lq_entry = lq_entry + 1) begin
          if (dut.u_load_queue.valid_q[lq_entry] &&
              (dut.u_load_queue.producer_id_q[lq_entry] == new_pid)) begin
            new_lq_found = 1'b1;
            new_lq_terminal_seen =
                dut.u_load_queue.terminal_seen_q[lq_entry];
          end
        end
        if ((dut.mem_terminal_ingress_valid_w != 12'b0) ||
            (dut.mem_terminal_ingress_accept_w != 12'b0) ||
            dut.lq_terminal0_valid_w || dut.lq_terminal1_valid_w ||
            !dut.mem_issue_res_valid_q ||
            !dut.mem_owner_live_mask_w[new_token] ||
            !new_lq_found || new_lq_terminal_seen) begin
          $display("[V11I-PRODUCTION-QUIET][FAIL] cycle=%0d old_pid=%h new_pid=%h token=%0d ingress=%b accept=%b lq_terminal=%b%b res=%0b live=%0b lq_found=%0b terminal_seen=%0b @%0t",
                   quiet_cycle, old_pid, new_pid, new_token,
                   dut.mem_terminal_ingress_valid_w,
                   dut.mem_terminal_ingress_accept_w,
                   dut.lq_terminal1_valid_w, dut.lq_terminal0_valid_w,
                   dut.mem_issue_res_valid_q,
                   dut.mem_owner_live_mask_w[new_token],
                   new_lq_found, new_lq_terminal_seen, $time);
          $fatal(1);
        end
        `TB_TICK(clk);
        #1;
      end

      // End only B's current holder through the production global-cancel
      // rule.  This is the sole post-wrap terminal and must drain exactly.
      flush = 1'b1;
      #1;
      if (!dut.mem_terminal_ingress_valid_w[6] ||
          !dut.mem_terminal_ingress_accept_w[6]) begin
        $display("[V11I-NEW-OWNER-TERMINAL][FAIL] token=%0d ingress=%0b accept=%0b @%0t",
                 new_token, dut.mem_terminal_ingress_valid_w[6],
                 dut.mem_terminal_ingress_accept_w[6], $time);
        $fatal(1);
      end
      `TB_TICK(clk);
      flush = 1'b0;
      clear_dispatch();
      #1;
      wait_cycles = 0;
      while (((rob_count != 0) || (issue_count != 0) ||
              (dut.lq_count_w != 0) ||
              (dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              dut.mem_issue_res_valid_q) &&
             (wait_cycles < 24)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      if ((rob_count != 0) || (issue_count != 0) ||
          (dut.lq_count_w != 0) ||
          (dut.mem_owner_live_count_w != 0) ||
          (dut.mem_terminal_pending_count_w != 0) ||
          dut.mem_issue_res_valid_q) begin
        $display("[V11I-NEW-OWNER-DRAIN][FAIL] rob=%0d iq=%0d lq=%0d live=%0d pending=%0d res=%0b @%0t",
                 rob_count, issue_count, dut.lq_count_w,
                 dut.mem_owner_live_count_w,
                 dut.mem_terminal_pending_count_w,
                 dut.mem_issue_res_valid_q, $time);
        $fatal(1);
      end
      for (quiet_cycle = 0; quiet_cycle < 3;
           quiet_cycle = quiet_cycle + 1) begin
        if ((dut.mem_terminal_ingress_valid_w != 12'b0) ||
            (dut.mem_terminal_ingress_accept_w != 12'b0)) begin
          $display("[V11I-POST-DRAIN-QUIET][FAIL] cycle=%0d ingress=%b accept=%b @%0t",
                   quiet_cycle, dut.mem_terminal_ingress_valid_w,
                   dut.mem_terminal_ingress_accept_w, $time);
          $fatal(1);
        end
        `TB_TICK(clk);
        #1;
      end
      $display("[V11I-TERMINAL-WRAP] owners=33 cursor_wrap=1 old_pid=%h new_pid=%h token=%0d pre_terminal_quiet=3 post_drain_quiet=3 new_owner_terminal=1 PASS",
               old_pid, new_pid, new_token);
`endif
    end
  endtask

  // V8W global-recovery isolation: owner A may already have been removed by
  // the MIQ flush compactor while its accepted bridge transaction still owes
  // a late drop.  A new correct-path owner B can then become the same-bank
  // head.  A's terminal must free only A's tracker lease and must never pop B.
  task automatic run_v8w_late_old_drop_new_head_isolation;
    reg [1:0] old_kind;
    reg [4:0] old_token;
    reg [1:0] old_epoch;
    reg [`XLEN-1:0] old_tval;
    reg [4:0] new_token;
    integer wait_cycles;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(64'h8000_6f00,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd21, 64'h8000_0580);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8W old owner request fire",
                dut.mem_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8W old owner MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      old_kind = dut.miq_head_owner_kind_w;
      old_token = dut.miq_head_owner_token_w;
      old_epoch = dut.miq_head_mmu_epoch_w;
      old_tval = dut.miq_head_fault_tval_w;

      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      tb_check32("V8W flush compacts old non-DRAIN owner",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("V8W old tracker lease waits bridge terminal",
                dut.mem_owner_live_mask_w[old_token], 1'b1);

      set_dispatch0(64'h8000_6f10,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd22, 64'h8000_0600);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8W new owner request fire",
                dut.mem_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8W new owner becomes same-bank head",
                 {28'b0, dut.miq_count_w}, 32'd1);
      new_token = dut.miq_head_owner_token_w;
      tb_check1("V8W new owner uses distinct live token",
                new_token != old_token, 1'b1);

      tb_mem_drop0_valid = 1'b1;
      tb_mem_drop0_owner_kind = old_kind;
      tb_mem_drop0_owner_token = old_token;
      tb_mem_drop0_mmu_epoch = old_epoch;
      tb_mem_drop0_fault_tval = old_tval;
      #1;
      tb_check1("V8W late old drop does not select MIQ pop",
                dut.miq_drop0_pop_w, 1'b0);
      tb_check1("V8W late old drop leaves queue pop invalid",
                dut.miq_queue_pop_valid_w, 1'b0);
      tb_check1("V8W late old drop enters collector",
                dut.mem_terminal_ingress_valid_w[2], 1'b1);
      tb_check1("V8W late old drop has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check32("V8W late old drop preserves new head token",
                 {27'b0, dut.miq_head_owner_token_w},
                 {27'b0, new_token});
      `TB_TICK(clk);
      tb_mem_drop0_valid = 1'b0;
      #1;
      tb_check32("V8W late old drop keeps new MIQ head",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check32("V8W late old drop keeps exact new token",
                 {27'b0, dut.miq_head_owner_token_w},
                 {27'b0, new_token});
      wait_cycles = 0;
      while (dut.mem_owner_live_mask_w[old_token] &&
             (wait_cycles < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("V8W late old drop frees only old lease",
                dut.mem_owner_live_mask_w[old_token], 1'b0);
      tb_check1("V8W late old drop preserves new lease",
                dut.mem_owner_live_mask_w[new_token], 1'b1);

      // The backend testbench bypasses the real bridge, so explicitly record
      // B's final-PA StoreQueue disposition before injecting a successful
      // LOAD response.  This is the same ordering event that the bridge emits
      // in integration; without it, the shared retire-resident LQ correctly
      // keeps a non-fault response closed.
      v8v_record_load_head_order(
          "V8W preserved new head", 1'b1,
          64'h0000_0000_a000_0600, 1'b0, {`XLEN{1'b0}});

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h7654_3210_fedc_ba98;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("V8W new head response remains consumable",
                mem_rsp_ready, 1'b1);
      tb_check1("V8W new head response pops MIQ",
                dut.miq_pop_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      commit_ready = 1'b1;
      #1;
      tb_check32("V8W new head response drains MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);
      wait_cycles = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              (rob_count != 0)) && (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("V8W late-drop isolation reaches memory idle",
                dut.mem_idle_o, 1'b1);
      $display("[V8W-LATE-OLD-DROP-NEW-HEAD-ISOLATION] old=%0d new=%0d PASS",
               old_token, new_token);
      reset_dut();
    end
  endtask

`ifdef V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
  // V8X closes the remaining V8W verification gap with one real combined
  // trace.  Both ordinary loads reside in bank0 MIQ while the canonical
  // wrapper holds A as its active AXI owner and B in its registered station.
  // A branch-mispredict recovery marks both owners; A drains its already-fired
  // AXI R and B terminates after station promotion, before any target request.
  task automatic run_v8x_backend_bridge_recovery_contract;
    reg [ROB_INDEX_W-1:0] boundary_rob;
    integer wait_cycles;
    integer quiet_cycles;
    begin
      seed_s2_g1_selective_kill_boundary(64'h8000_6f20,
                                         boundary_rob);
      tb_check1("V8X wrapper global flush initially low", flush, 1'b0);

      set_dispatch0(V8X_A_PC,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd23, V8X_A_ADDR);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8X A captures real memory reservation",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8X A fires into real bridge station",
                dut.mem_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8X A occupies bank0 MIQ",
                 {28'b0, dut.miq_count_w}, 32'd1);

      set_dispatch0(V8X_B_PC,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd24, V8X_B_ADDR);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8X B captures real memory reservation",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8X B fires into real bridge station",
                dut.mem_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8X same-bank MIQ contains A and B",
                 {28'b0, dut.miq_count_w}, 32'd2);
      tb_check32("V8X other-bank MIQ remains empty",
                 {28'b0, dut.miq1_count_w}, 32'd0);
      tb_check1("V8X A/B addresses select bank0",
                !V8X_A_ADDR[3] && !V8X_B_ADDR[3], 1'b1);

      // Freeze immutable owner identities before expected/head outputs can
      // advance.  The ledger uses these copies for both terminal cycles.
      v8x_owner_a_kind_q = dut.miq_head_owner_kind_w;
      v8x_owner_a_token_q = dut.miq_head_owner_token_w;
      v8x_owner_a_epoch_q = dut.miq_head_mmu_epoch_w;
      v8x_owner_a_tval_q = dut.miq_head_fault_tval_w;
      v8x_owner_b_kind_q = dut.miq_next_head_owner_kind_w;
      v8x_owner_b_token_q = dut.miq_next_head_owner_token_w;
      v8x_owner_b_epoch_q = dut.miq_next_head_mmu_epoch_w;
      v8x_owner_b_tval_q = dut.miq_next_head_fault_tval_w;
      tb_check1("V8X A/B use distinct tracker tokens",
                v8x_owner_a_token_q != v8x_owner_b_token_q, 1'b1);
      tb_check64("V8X A immutable fault tval", v8x_owner_a_tval_q,
                 V8X_A_ADDR);
      tb_check64("V8X B immutable fault tval", v8x_owner_b_tval_q,
                 V8X_B_ADDR);

      // Hold ARREADY low until both real wrapper holders are visible.
      wait_cycles = 0;
      while ((!v8x_d_axi_arvalid ||
              !v8x_bridge.u_bridge0.stg_valid_q ||
              (v8x_bridge.u_bridge0.active_owner_token_q !=
               v8x_owner_a_token_q) ||
              (v8x_bridge.u_bridge0.stg_owner_token_q !=
               v8x_owner_b_token_q)) && (wait_cycles < 40)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("V8X A reaches shared AXI AR", v8x_d_axi_arvalid, 1'b1);
      tb_check64("V8X A shared AXI AR address", v8x_d_axi_araddr,
                 V8X_A_ADDR);
      tb_check1("V8X bridge0 active query names A",
                v8x_lane0_owner_query_valid &&
                (v8x_lane0_owner_query_token == v8x_owner_a_token_q),
                1'b1);
      tb_check1("V8X bridge0 station query names B",
                v8x_lane0_station_query_valid &&
                (v8x_lane0_station_query_token == v8x_owner_b_token_q),
                1'b1);
      tb_check1("V8X backend active tracker truth names A",
                mem_tracker_expected_valid &&
                (mem_tracker_expected_owner_kind == v8x_owner_a_kind_q) &&
                (mem_tracker_expected_owner_token == v8x_owner_a_token_q) &&
                (mem_tracker_expected_mmu_epoch == v8x_owner_a_epoch_q),
                1'b1);
      tb_check1("V8X backend station truth names B",
                mem_station_expected_valid &&
                (mem_station_expected_owner_kind == v8x_owner_b_kind_q) &&
                (mem_station_expected_owner_token == v8x_owner_b_token_q) &&
                (mem_station_expected_mmu_epoch == v8x_owner_b_epoch_q),
                1'b1);
      tb_check1("V8X bridge residency contains A and B",
                v8x_lane0_owner_residency_mask[v8x_owner_a_token_q] &&
                v8x_lane0_owner_residency_mask[v8x_owner_b_token_q],
                1'b1);
      tb_check32("V8X no AR handshake before explicit accept",
                 v8x_ar_fire_count_q, 32'd0);

      v8x_d_axi_arready = 1'b1;
      #1;
      tb_check1("V8X A shared AR exact handshake",
                v8x_d_axi_arvalid && v8x_d_axi_arready, 1'b1);
      `TB_TICK(clk);
      v8x_d_axi_arready = 1'b0;
      #1;
      tb_check32("V8X exactly one shared AR fired",
                 v8x_ar_fire_count_q, 32'd1);
      tb_check1("V8X bridge waits for A read data",
                v8x_d_axi_rready, 1'b1);
      tb_check1("V8X B remains registered station while A waits R",
                v8x_bridge.u_bridge0.stg_valid_q &&
                (v8x_bridge.u_bridge0.stg_owner_token_q ==
                 v8x_owner_b_token_q), 1'b1);

      // One-cycle selective branch recovery.  This is an RTL branch-resolve
      // event, not wrapper/global flush; no R is present, so A must hold its
      // transport owner while both MIQ entries latch their killed state.
      t3v_force_branch_rob = boundary_rob;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      #1;
      tb_check1("V8X same-cycle A effective killed",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("V8X same-cycle B effective killed",
                dut.miq_next_head_effective_killed_w, 1'b1);
      tb_check1("V8X selective recovery keeps wrapper flush low",
                flush, 1'b0);
      tb_check1("V8X A waits for R before exact drop",
                v8x_lane0_drop0_valid, 1'b0);
      `TB_TICK(clk);
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      tb_check1("V8X A persistent killed bit latched",
                dut.miq_head_killed_w, 1'b1);
      tb_check1("V8X B persistent killed bit latched",
                dut.miq_next_head_killed_w, 1'b1);
      tb_check1("V8X active A exact selective authority",
                v8x_bridge.u_bridge0.active_selective_recovery_w, 1'b1);
      tb_check1("V8X recovery presents no new AR",
                v8x_d_axi_arvalid, 1'b0);

      // A's already-owned downstream R is drained.  The bridge must emit a
      // raw drop, backend must pop the same MIQ head, and collector lane2 must
      // capture the exact 9-bit owner identity on this edge.
      v8x_d_axi_rvalid = 1'b1;
      v8x_d_axi_rdata = 64'h1122_3344_5566_7788;
      v8x_d_axi_rresp = 2'b00;
      #1;
      tb_check1("V8X A late R handshake",
                v8x_d_axi_rvalid && v8x_d_axi_rready, 1'b1);
      tb_check1("V8X A late R becomes exact bridge drop",
                v8x_lane0_drop0_valid &&
                (v8x_lane0_drop0_owner_token == v8x_owner_a_token_q),
                1'b1);
      tb_check1("V8X A drop selects exact MIQ pop",
                dut.miq_queue_pop_valid_w && dut.miq_pop_owner_match_w,
                1'b1);
      tb_check1("V8X A drop enters collector lane2",
                dut.mem_terminal_ingress_valid_w[2], 1'b1);
      tb_check1("V8X A killed R emits no response", v8x_lane0_rsp_valid,
                1'b0);
      tb_check1("V8X A killed R emits no WB", dut.mem_wb_fire_w, 1'b0);
      tb_check1("V8X A killed R emits no cache fill",
                v8x_bridge.u_bridge0.dcache_read_fill_valid_w, 1'b0);
      `TB_TICK(clk);
      v8x_d_axi_rvalid = 1'b0;
      v8x_d_axi_rdata = {`XLEN{1'b0}};
      #1;
      tb_check32("V8X A terminal leaves B as sole MIQ owner",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("V8X MIQ head advances to frozen B",
                dut.miq_head_valid_w &&
                (dut.miq_head_owner_token_w == v8x_owner_b_token_q) &&
                dut.miq_head_killed_w, 1'b1);
      tb_check32("V8X ledger recorded only A group",
                 v8x_ledger_step_q, 32'd1);

      // In S_IDLE the registered station advances on the next edge.  B is now
      // the exact persistent-killed MIQ head, so S_SQ_QUERY terminates before
      // lookup/translation/AXI presentation.
      `TB_TICK(clk);
      #1;
      tb_check1("V8X station B promotes to active B",
                v8x_lane0_owner_query_valid &&
                (v8x_bridge.u_bridge0.active_owner_token_q ==
                 v8x_owner_b_token_q) &&
                !v8x_bridge.u_bridge0.stg_valid_q, 1'b1);
      tb_check1("V8X promoted B tracker truth is exact",
                mem_tracker_expected_valid &&
                (mem_tracker_expected_owner_kind == v8x_owner_b_kind_q) &&
                (mem_tracker_expected_owner_token == v8x_owner_b_token_q) &&
                (mem_tracker_expected_mmu_epoch == v8x_owner_b_epoch_q),
                1'b1);
      tb_check1("V8X promoted B keeps selective recovery authority",
                v8x_bridge.u_bridge0.active_selective_recovery_w, 1'b1);
      tb_check1("V8X promoted B drops before target request",
                v8x_lane0_drop0_valid &&
                (v8x_lane0_drop0_owner_token == v8x_owner_b_token_q) &&
                !v8x_d_axi_arvalid &&
                !v8x_bridge.u_bridge0.lsu_axi_arvalid_o, 1'b1);
      tb_check1("V8X B drop selects exact MIQ pop",
                dut.miq_queue_pop_valid_w && dut.miq_pop_owner_match_w,
                1'b1);
      tb_check1("V8X B drop enters collector lane2",
                dut.mem_terminal_ingress_valid_w[2], 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8X B terminal drains bank0 MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check32("V8X ledger records A then B",
                 v8x_ledger_step_q, 32'd2);

      commit_ready = 1'b1;
      wait_cycles = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              (rob_count != 0) || !v8x_lane0_idle ||
              !v8x_lane1_idle) && (wait_cycles < 24)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check32("V8X tracker lease count drains",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check32("V8X terminal collector drains",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
      tb_check32("V8X ROB drains killed A/B and older branch",
                 {{(32-ROB_COUNT_W){1'b0}}, rob_count}, 32'd0);
      tb_check1("V8X both real bridges reach idle",
                v8x_lane0_idle && v8x_lane1_idle, 1'b1);
      tb_check32("V8X exact bridge drop count", v8x_drop0_count_q,
                 32'd2);
      tb_check32("V8X exact MIQ pop count", v8x_miq_pop_count_q,
                 32'd2);
      tb_check32("V8X exact collector ingress count",
                 v8x_terminal_count_q, 32'd2);
      tb_check32("V8X shared AR fire count remains one",
                 v8x_ar_fire_count_q, 32'd1);
      tb_check32("V8X no post-recovery AR presentation",
                 v8x_post_recovery_arvalid_count_q, 32'd0);
      tb_check32("V8X no station-drop terminal", v8x_drop1_count_q,
                 32'd0);
      tb_check32("V8X no bridge response", v8x_rsp_count_q, 32'd0);
      tb_check32("V8X no memory WB", v8x_mem_wb_count_q, 32'd0);
      tb_check32("V8X no A/B commit", v8x_commit_ab_count_q, 32'd0);
      tb_check32("V8X no killed-load cache fill",
                 v8x_dcache_fill_count_q, 32'd0);
      tb_check32("V8X no lane1 bridge owner", v8x_lane1_event_count_q,
                 32'd0);

      // A stable guard window rules out late duplicate terminal or target
      // side effects after the first observed empty/idle cycle.
      for (quiet_cycles = 0; quiet_cycles < 6;
           quiet_cycles = quiet_cycles + 1) begin
        tb_check1("V8X quiet window no AR valid", v8x_d_axi_arvalid,
                  1'b0);
        tb_check1("V8X quiet window no drop0", v8x_lane0_drop0_valid,
                  1'b0);
        tb_check1("V8X quiet window no MIQ pop",
                  dut.miq_queue_pop_valid_w, 1'b0);
        tb_check1("V8X quiet window no terminal ingress",
                  |dut.mem_terminal_ingress_valid_w, 1'b0);
        tb_check1("V8X quiet window no memory WB",
                  dut.mem_wb_fire_w || dut.mem1_wb_fire_w, 1'b0);
        tb_check1("V8X quiet window no cache fill",
                  v8x_bridge.u_bridge0.dcache_read_fill_valid_w ||
                  v8x_bridge.u_bridge1.dcache_read_fill_valid_w, 1'b0);
        `TB_TICK(clk);
        #1;
      end
      tb_check32("V8X guard keeps exact drop count", v8x_drop0_count_q,
                 32'd2);
      tb_check32("V8X guard keeps exact terminal count",
                 v8x_terminal_count_q, 32'd2);
      tb_check32("V8X guard keeps one AR", v8x_ar_fire_count_q, 32'd1);
      $display("[V8X-BACKEND-BRIDGE-RECOVERY] A=%0d B=%0d ar=1 drop=2 pop=2 terminal=2 wb=0 commit=0 fill=0 lane1=0 quiet=6 PASS",
               v8x_owner_a_token_q, v8x_owner_b_token_q);
      reset_dut();
    end
  endtask
`endif

  task automatic seed_s2_g1_amo_read;
    input [`XLEN-1:0] pc;
    output [4:0] owner_token;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b1;
      set_dispatch0(pc,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b0),
                    5'd0, 5'd0, 5'd19, 64'd0);
      dispatch0_inst = inst_amo(5'b00000, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd19);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("S2-G1 AMO read", 1'b0, 64'd0,
                        1'b0, {`XLEN{1'b0}},
                        1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      tb_check32("S2-G1 AMO read MIQ resident",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("S2-G1 AMO read pending", dut.mem_pending_q, 1'b1);
      owner_token = dut.miq_head_owner_token_w;
    end
  endtask

  // S2-G1 AMO read/restore priority, inter-phase lane9 accounting and the
  // selected-grant-only write transition are checked independently.
  task automatic run_s2_g1_amo_restore_and_grant_contract;
    reg [4:0] owner_token;
    integer wait_cycles;
    begin
      seed_s2_g1_amo_read(64'h8000_6ec0, owner_token);
      checkpoint_restore = 1'b1;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0102_0304_0506_0708;
      force dut.wb_slot_free_w = 1'b0;
      #1;
      tb_check1("S2-G1 AMO read+restore effective kill",
                dut.miq_head_effective_killed_w, 1'b1);
      tb_check1("S2-G1 AMO read+restore drains without WB credit",
                mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 AMO read+restore is final",
                dut.mem_rsp_final_fire_w, 1'b1);
      tb_check1("S2-G1 AMO read+restore cannot enter write phase",
                dut.mem_amo_read_rsp_w, 1'b0);
      tb_check1("S2-G1 AMO read+restore has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 AMO read+restore lane0 terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b1);
      tb_check1("S2-G1 AMO read+restore no lane9 duplicate",
                dut.mem_terminal_ingress_valid_w[9], 1'b0);
      tb_check1("S2-G1 AMO read+restore no request",
                mem_req_valid, 1'b0);
      tb_check1("S2-G1 AMO read+restore no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      mem_rsp_valid = 1'b0;
      release dut.wb_slot_free_w;
      #1;
      tb_check1("S2-G1 AMO read+restore clears pending",
                dut.mem_pending_q, 1'b0);
      tb_check32("S2-G1 AMO read+restore drains MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 AMO read+restore owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);

      seed_s2_g1_amo_read(64'h8000_6ee0, owner_token);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'd7;
      #1;
      tb_check1("S2-G1 AMO read success enters interphase",
                dut.mem_amo_read_rsp_w, 1'b1);
      tb_check1("S2-G1 AMO read success is not terminal",
                dut.mem_terminal_ingress_valid_w[0], 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("S2-G1 AMO write phase resident",
                dut.mem_amo_write_phase_q, 1'b1);
      tb_check1("S2-G1 AMO write not sent",
                dut.mem_amo_write_sent_q, 1'b0);
      tb_check32("S2-G1 AMO read popped MIQ",
                 {28'b0, dut.miq_count_w}, 32'd0);

      checkpoint_restore = 1'b1;
      #1;
      tb_check1("S2-G1 AMO interphase cancel",
                dut.mem_amo_interphase_cancel_w, 1'b1);
      tb_check1("S2-G1 AMO interphase lane9",
                dut.mem_terminal_ingress_valid_w[9], 1'b1);
      tb_check32("S2-G1 AMO interphase token",
                 {27'b0, dut.mem_terminal_ingress_token_w[49:45]},
                 {27'b0, owner_token});
      tb_check1("S2-G1 AMO interphase restore gates request",
                mem_req_valid, 1'b0);
      tb_check1("S2-G1 AMO interphase restore gates push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check1("S2-G1 AMO interphase clears pending",
                dut.mem_pending_q, 1'b0);
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 AMO lane9 owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);

      seed_s2_g1_amo_read(64'h8000_6f00, owner_token);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'd9;
      #1;
      tb_check1("S2-G1 AMO grant seed read response",
                dut.mem_amo_read_rsp_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      force dut.grant_amo_write_w = 1'b0;
      #1;
      tb_check1("S2-G1 AMO raw write remains eligible",
                dut.mem_amo_write_req_valid_w, 1'b1);
      tb_check1("S2-G1 AMO unselected write has no request",
                mem_req_valid, 1'b0);
      tb_check1("S2-G1 AMO unselected write has no push",
                dut.push_amo_write_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 AMO unselected write stays unsent",
                dut.mem_amo_write_sent_q, 1'b0);
      release dut.grant_amo_write_w;
      #1;
      tb_check1("S2-G1 AMO selected write requests",
                mem_req_valid, 1'b1);
      tb_check1("S2-G1 AMO selected write pushes",
                dut.push_amo_write_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("S2-G1 AMO selected write sent once",
                dut.mem_amo_write_sent_q, 1'b1);
      tb_check32("S2-G1 AMO selected write MIQ owner",
                 {28'b0, dut.miq_count_w}, 32'd1);
      tb_check1("v8g AMO post-launch ROB head remains open",
                dut.rob_head_launch_open_w, 1'b1);
      tb_check1("v8g AMO post-launch ROB entry remains unfinished",
                dut.u_dispatch_backend.u_rob.done_q[
                  dut.mem_producer_id_q[ROB_INDEX_W-1:0]], 1'b0);
      tb_check32("v8g AMO post-launch owner lease remains live",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd1);
      tb_check1("v8g AMO post-launch cannot retire before final response",
                commit0_valid, 1'b0);
      tb_check1("S2-G1 AMO selected write does not repeat",
                mem_req_valid, 1'b0);

      // Model a closed ROB observation only combinationally.  Because the
      // physical AMO write already fired, this exact response is irreversible
      // poison: transport may drain, but no normal final/WB/death is legal.
      force dut.mem_completion_rob_open_w = 1'b0;
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("v8g AMO closed-final enters fatal quarantine",
                dut.mem_fatal_irrevocable_response_w, 1'b1);
      tb_check1("v8g AMO closed-final drains transport",
                mem_rsp_ready, 1'b1);
      tb_check1("v8g AMO closed-final cannot normal-final",
                dut.mem_rsp_final_fire_w, 1'b0);
      tb_check1("v8g AMO closed-final has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("v8g AMO closed-final has no collector death",
                dut.mem_terminal_ingress_valid_w[0], 1'b0);
      mem_rsp_valid = 1'b0;
      release dut.mem_completion_rob_open_w;
      #1;

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = { `XLEN{1'b0} };
      #1;
      tb_check1("S2-G1 AMO selected write response ready",
                mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      for (wait_cycles = 0;
           (wait_cycles < 6) && (dut.mem_owner_live_count_w != 6'd0);
           wait_cycles = wait_cycles + 1) begin
        `TB_TICK(clk);
        #1;
      end
      tb_check32("S2-G1 AMO selected write owner frees once",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      $display("[V8G-AMO-POST-LAUNCH] write_sent keeps exact-open unfinished ROB/PID lease until final response PASS");
      $display("[T4S-AMO-RESTORE] read+restore lane0, interphase lane9, selected-grant-only write PASS");
      reset_dut();
    end
  endtask

  task automatic run_s2_g1_empty_miq_stale_drain_contract;
    begin
      reset_dut();
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'hdead_beef_cafe_f00d;
      #1;
      tb_check32("S2-G1 stale drain starts empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check1("S2-G1 stale drain transport ready", mem_rsp_ready, 1'b1);
      tb_check1("S2-G1 stale drain presents pop transport",
                dut.miq_pop_transport_w, 1'b1);
      tb_check1("S2-G1 stale drain has no exact pop",
                dut.miq_pop_w, 1'b0);
      tb_check1("S2-G1 stale drain has no WB",
                dut.mem_wb_fire_w, 1'b0);
      tb_check1("S2-G1 stale drain has no terminal",
                |dut.mem_terminal_ingress_valid_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check32("S2-G1 stale drain remains empty",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check32("S2-G1 stale drain creates no owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      $display("[T4S-STALE-DRAIN] empty MIQ drains transport with zero side effects PASS");
      reset_dut();
    end
  endtask

  // MIQ full+head-pop must backpressure the parent for one cycle.  The fifth
  // request remains in the memory station, then fires on the cycle after the
  // old head pop with its original metadata.
  task automatic run_t3v_miq_full_pop_parent_backpressure_contract;
    integer fill_idx;
    reg [ROB_INDEX_W-1:0] fifth_rob;
    reg [PHY_REG_ADDR_W-1:0] fifth_pdest;
    reg [`XLEN-1:0] fill_addr;
    begin
      reset_dut();
      mem_req_ready = 1'b1;
      mem_rsp_valid = 1'b0;

      for (fill_idx = 0; fill_idx < 4; fill_idx = fill_idx + 1) begin
        fill_addr = 64'h8000_0400 + (fill_idx * 64'd8);
        set_dispatch0(64'h8000_6e00 + (fill_idx * 64'd4),
                      make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                      5'd0, 5'd0, 5'd12 + fill_idx, fill_addr);
        #1;
        tb_check1("T3V MIQ fill dispatch ready", dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        tb_check1("T3V MIQ fill capture pending",
                  dut.mem_issue_res_capture_w, 1'b1);
        `TB_TICK(clk);
        #1;
        tb_check1("T3V MIQ fill request fires",
                  dut.issue0_mem_request_fire_w, 1'b1);
        tb_check64("T3V MIQ fill request address",
                   dut.miq_push_addr_w, fill_addr);
        `TB_TICK(clk);
        #1;
        tb_check32("T3V MIQ fill count increments",
                   {28'b0, dut.miq_count_w}, fill_idx + 1);
      end
      tb_check1("T3V MIQ reaches full", dut.miq_full_w, 1'b1);

      set_dispatch0(32'h8000_6e10,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd16, 64'h8000_0440);
      #1;
      fifth_rob = dut.dispatch0_rob_idx_w;
      fifth_pdest = dut.dispatch0_pdest_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V MIQ fifth capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V MIQ fifth station resident",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T3V MIQ full blocks fifth request", mem_req_valid, 1'b0);

      // Pop the old head while full.  Parent credit is based on old full, so
      // no fifth request/consume/push is allowed in this cycle.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1111_2222_3333_4444;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("T3V MIQ full-pop response ready", mem_rsp_ready, 1'b1);
      tb_check1("T3V MIQ full-pop really pops", dut.miq_pop_w, 1'b1);
      tb_check1("T3V MIQ full-pop keeps old full visible", dut.miq_full_w, 1'b1);
      tb_check1("T3V MIQ full-pop parent request blocked", mem_req_valid, 1'b0);
      tb_check1("T3V MIQ full-pop station not consumed",
                dut.mem_issue_res_consume_fire_w, 1'b0);
      tb_check1("T3V MIQ full-pop has no push",
                dut.miq_push_valid_w, 1'b0);
      tb_check1("T3V MIQ full-pop has no buffer handoff",
                dut.issue0_mem_buffer_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      // Old pop has now created real credit.  The same station request fires
      // exactly one cycle later and carries the fifth uop's frozen metadata.
      tb_check32("T3V MIQ post-pop count is three",
                 {28'b0, dut.miq_count_w}, 32'd3);
      tb_check1("T3V MIQ fifth station survives pop",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("T3V MIQ fifth request fires next cycle",
                dut.issue0_mem_request_fire_w, 1'b1);
      tb_check1("T3V MIQ fifth owns push", dut.push_issue0_w, 1'b1);
      tb_check32("T3V MIQ fifth push ROB",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.miq_push_rob_w},
                 {{(32-ROB_INDEX_W){1'b0}}, fifth_rob});
      tb_check32("T3V MIQ fifth push pdest",
                 {{(32-PHY_REG_ADDR_W){1'b0}}, dut.miq_push_pdest_w},
                 {{(32-PHY_REG_ADDR_W){1'b0}}, fifth_pdest});
      tb_check32("T3V MIQ fifth push size",
                 {30'b0, dut.miq_push_size_w},
                 {30'b0, `MEM_SIZE_DWORD});
      tb_check1("T3V MIQ fifth push unsigned",
                dut.miq_push_unsigned_w, 1'b1);
      tb_check64("T3V MIQ fifth push address",
                 dut.miq_push_addr_w, 64'h8000_0440);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V MIQ fifth station clears after fire",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check32("T3V MIQ returns to full after fifth push",
                 {28'b0, dut.miq_count_w}, 32'd4);
      $display("[T3V-MIQ-FULL-POP] fifth_rob=%0d fifth_pdest=%0d addr=0x%016h",
               fifth_rob, fifth_pdest, 64'h8000_0440);
      reset_dut();
    end
  endtask

  // T3V LR/SC reservation identity includes access width.  A same-address SC
  // with a different width is a local failure (status=1, no request).  A
  // same-width SC whose byte address is misaligned can still match the LR
  // reservation granule, but must complete as a precise local exception and
  // consume the reservation.
  task automatic run_t3v_lrsc_width_and_exception_contract;
    begin
      // LR.W -> SC.D at the same naturally aligned address: address match is
      // insufficient; width mismatch must force a local failed-SC completion.
      reset_dut();
      set_dispatch0(32'h8000_6da0,
                    make_amo_ctrl(`MEM_SIZE_WORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd20, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LW, 5'd20);
      #1;
      tb_check1("T3V LR.W seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T3V LR.W seed", 1'b0, 64'h0000_0380,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      // The in-order bridge cannot return a response before the request
      // station fire has created its MIQ owner.
      `TB_TICK(clk);
      #1;
      complete_mem0_response("T3V LR.W seed", 64'h0000_0000_89ab_cdef,
                             1'b1, 1'b1, 1'b1,
                             64'hffff_ffff_89ab_cdef);
      tb_check1("T3V LR.W establishes reservation",
                dut.reservation_valid_q, 1'b1);
      tb_check32("T3V LR.W reservation remembers word width",
                 {30'b0, dut.reservation_size_q},
                 {30'b0, `MEM_SIZE_WORD});

      set_dispatch0(32'h8000_6da4,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd21, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00011, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd21);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V LR.W-SC.D capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D width mismatch",
                dut.issue0_sc_success_w, 1'b0);
      tb_check1("T3V LR.W-SC.D consumes locally",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("T3V LR.W-SC.D has no request", mem_req_valid, 1'b0);
      tb_check1("T3V LR.W-SC.D has no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D formal WB visible", dut.wb0_valid_w, 1'b1);
      tb_check64("T3V LR.W-SC.D formal status is one",
                 dut.wb0_data_w, 64'd1);
      tb_check1("T3V LR.W-SC.D has no commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3V LR.W-SC.D clears reservation",
                dut.reservation_valid_q, 1'b0);
      tb_check1("T3V LR.W-SC.D never reaches bridge", mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D commits failed status from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3V LR.W-SC.D Q status is one", commit0_data, 64'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.W-SC.D completion does not repeat",
                commit0_valid, 1'b0);

      // Reverse mismatch: LR.D -> SC.W must obey the same identity rule.
      reset_dut();
      set_dispatch0(32'h8000_6db0,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd22, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd22);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T3V LR.D seed", 1'b0, 64'h0000_0380,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      complete_mem0_response("T3V LR.D seed", 64'h1122_3344_5566_7788,
                             1'b1, 1'b1, 1'b1,
                             64'h1122_3344_5566_7788);
      tb_check1("T3V LR.D establishes reservation",
                dut.reservation_valid_q, 1'b1);
      tb_check32("T3V LR.D reservation remembers dword width",
                 {30'b0, dut.reservation_size_q},
                 {30'b0, `MEM_SIZE_DWORD});

      set_dispatch0(32'h8000_6db4,
                    make_amo_ctrl(`MEM_SIZE_WORD, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd23, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00011, 5'd0, 5'd0,
                                `FUNCT3_LW, 5'd23);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V LR.D-SC.W capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W width mismatch",
                dut.issue0_sc_success_w, 1'b0);
      tb_check1("T3V LR.D-SC.W consumes locally",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("T3V LR.D-SC.W has no request", mem_req_valid, 1'b0);
      tb_check1("T3V LR.D-SC.W has no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W formal WB visible", dut.wb0_valid_w, 1'b1);
      tb_check64("T3V LR.D-SC.W formal status is one",
                 dut.wb0_data_w, 64'd1);
      tb_check1("T3V LR.D-SC.W has no commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3V LR.D-SC.W clears reservation",
                dut.reservation_valid_q, 1'b0);
      tb_check1("T3V LR.D-SC.W never reaches bridge", mem_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W commits failed status from ROB Q",
                commit0_valid, 1'b1);
      tb_check64("T3V LR.D-SC.W Q status is one", commit0_data, 64'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V LR.D-SC.W completion does not repeat",
                commit0_valid, 1'b0);

      // LR.D reserves the 8-byte granule at 0x380.  SC.D at 0x384 still
      // matches that granule but is itself misaligned: exception, no request,
      // and the reservation must be consumed exactly once.
      reset_dut();
      set_dispatch0(32'h8000_6dc0,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b1, 1'b0),
                    5'd0, 5'd0, 5'd24, 64'h0000_0380);
      dispatch0_inst = inst_amo(5'b00010, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd24);
      `TB_TICK(clk);
      clear_dispatch();
      wait_mem0_request("T3V LR.D misalign seed", 1'b0, 64'h0000_0380,
                        1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
      `TB_TICK(clk);
      #1;
      complete_mem0_response("T3V LR.D misalign seed",
                             64'ha5a5_5a5a_0123_4567,
                             1'b1, 1'b1, 1'b1,
                             64'ha5a5_5a5a_0123_4567);
      tb_check1("T3V misalign seed reservation valid",
                dut.reservation_valid_q, 1'b1);

      set_dispatch0(32'h8000_6dc4,
                    make_amo_ctrl(`MEM_SIZE_DWORD, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd25, 64'h0000_0384);
      dispatch0_inst = inst_amo(5'b00011, 5'd0, 5'd0,
                                `FUNCT3_LD, 5'd25);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3V matching misaligned SC capture pending",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC sees reservation",
                dut.issue0_sc_success_w, 1'b1);
      tb_check1("T3V matching misaligned SC is local exception",
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("T3V matching misaligned SC consumes locally",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("T3V matching misaligned SC has no request",
                mem_req_valid, 1'b0);
      tb_check1("T3V matching misaligned SC has no MIQ push",
                dut.miq_push_valid_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC formal WB visible",
                dut.wb0_valid_w, 1'b1);
      tb_check1("T3V matching misaligned SC formal exception",
                dut.wb0_exception_w, 1'b1);
      tb_check32("T3V matching misaligned SC formal cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64("T3V matching misaligned SC formal tval",
                 dut.wb0_tval_w, 64'h0000_0384);
      tb_check1("T3V matching misaligned SC has no commit on formal WB",
                commit0_valid, 1'b0);
      tb_check1("T3V matching misaligned SC clears reservation",
                dut.reservation_valid_q, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("T3V matching misaligned SC Q exception",
                commit0_exception, 1'b1);
      tb_check32("T3V matching misaligned SC Q cause",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}}, `EXC_STORE_ADDR_MISALIGN});
      tb_check64("T3V matching misaligned SC Q tval",
                 commit0_tval, 64'h0000_0384);
      `TB_TICK(clk);
      #1;
      tb_check1("T3V matching misaligned SC completion does not repeat",
                commit0_valid, 1'b0);
      $display("[T3V-LRSC-WIDTH-MISALIGN] mismatch_pairs=2 matching_misaligned=1 reservation_valid=%0b",
               dut.reservation_valid_q);
      reset_dut();
    end
  endtask

  // R3：锁住物理 ALU terminal 的资源边界，而非程序序 lane 语义。它仍完成
  // fixed-latency ALU，但 LSU/request/MIQ owner 均归唯一 Universal terminal。
  task automatic run_r3_alu_terminal_no_lsu_contract;
    begin
      reset_dut();
      set_dispatch0(32'h8000_6dc0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd3, 64'd11);
      set_dispatch1(32'h8000_6dc4,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd4, 64'd13);
      #1;
      tb_check1("R3 terminal contract dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3 terminal contract dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("R3 live physical ALU-terminal owner",
                dut.issue1_valid_w, 1'b1);
      tb_check1("R3 live physical ALU-terminal fires",
                dut.issue1_fire_w, 1'b1);
      tb_check1("R3 ALU terminal load class is zero",
                dut.issue1_is_load_w, 1'b0);
      tb_check1("R3 ALU terminal store class is zero",
                dut.issue1_is_store_w, 1'b0);
      tb_check1("R3 ALU terminal AMO class is zero",
                dut.issue1_is_amo_w, 1'b0);
      tb_check1("R3 ALU terminal memory owner is zero",
                dut.issue1_is_mem_w, 1'b0);
      tb_check1("R3 ALU terminal request valid is zero",
                dut.issue1_mem_req_valid_w, 1'b0);
      tb_check1("R3 ALU terminal request fire is zero",
                dut.issue1_mem_request_fire_w, 1'b0);
      tb_check1("R3 ALU terminal MIQ owner is zero",
                dut.push_issue1_w, 1'b0);
      tb_check1("R3 ALU terminal emits no memory request",
                mem_req_valid, 1'b0);
      $display("[R3-ALU-TERMINAL-NO-LSU] live=%0b fire=%0b req=%0b push=%0b",
               dut.issue1_valid_w, dut.issue1_fire_w,
               dut.issue1_mem_req_valid_w, dut.push_issue1_w);
      reset_dut();
    end
  endtask

  // R3.1 P0: a younger ordinary load may reserve/present valid before ROB
  // head, but its unknown request attr must remain invalid/RSVD.  Final IO
  // serialization is owned by bridge plus the exact MIQ/ROB release signal.
  task automatic run_r3p1_swapped_mmio_atomic_contract;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_6dd0,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'd17);
      set_dispatch1(32'h8000_6dd4,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'h0000_0200);
      #1;
      tb_check1("R3.1 MMIO pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("R3.1 MMIO pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      force dut.mem_rsp_waiting_for_wb_w = 1'b1;
      #1;
      tb_check1("R3.1 MMIO pair is capability-swapped",
                dut.iq_issue_pair_swapped_w, 1'b1);
      tb_check32("R3.1 MMIO Universal owns younger",
                 dut.iq_issue0_pc_w[31:0], 32'h8000_6dd4);
      tb_check32("R3.1 MMIO ALU terminal owns older",
                 dut.issue1_pc_w[31:0], 32'h8000_6dd0);
      tb_check1("R3.1 ready10 blocks memory IQ pop",
                dut.iq_issue0_ready_w, 1'b0);
      tb_check1("R3.1 ready10 blocks reservation capture",
                dut.mem_issue_res_capture_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("R3.1 ready10 holds both IQ entries",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("R3.1 ready10 leaves reservation empty",
                dut.mem_issue_res_valid_q, 1'b0);

      release dut.mem_rsp_waiting_for_wb_w;
      #1;
      tb_check1("R3.1 ready11 older ALU fires", dut.issue1_fire_w, 1'b1);
      tb_check1("R3.1 ready11 younger MMIO captures",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("R3.1 ready11 drains pair from IQ",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("R3.1 MMIO reservation established",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("R3.1 older ALU reaches WB1", dut.wb1_valid_w, 1'b1);
      tb_check1("R3.1 no retire on older formal WB", commit0_valid, 1'b0);
      tb_check1("R3.1 ordinary load may present valid before older retires",
                mem_req_valid, 1'b1);
      tb_check1("R3.1 backpressure prevents early request fire",
                dut.mem_req_fire_any_w, 1'b0);
      tb_check1("R3.1 early request attr invalid",
                mem_req_attr_valid, 1'b0);
      tb_check32("R3.1 early request class poison",
                 {30'b0, mem_req_class},
                 {30'b0, `OOO_MEM_CLASS_RSVD});

      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 older ALU retires before MMIO", commit0_valid, 1'b1);
      tb_check32("R3.1 older ALU retire PC", commit0_pc[31:0],
                 32'h8000_6dd0);
      tb_check1("R3.1 load valid remains held under backpressure",
                mem_req_valid, 1'b1);
      tb_check1("R3.1 held load still has no request fire",
                dut.mem_req_fire_any_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 older ALU retires exactly once", commit0_valid, 1'b0);

      mem_req_ready = 1'b1;
      #1;
      tb_check1("R3.1 ordinary request remains live at ROB head",
                mem_req_valid, 1'b1);
      tb_check1("R3.1 MMIO request is read", mem_req_write, 1'b0);
      tb_check64("R3.1 MMIO request address", mem_req_addr, 64'h0000_0200);
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 IO candidate request fires exactly once",
                mem_req_valid, 1'b0);
      tb_check1("R3.1 exact MIQ owner enables device release",
                mem_req_device_release, 1'b1);
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_IO;
      mem_rsp_cacheable = 1'b0;
      complete_mem0_response("R3.1 swapped MMIO", 64'h0000_0000_1234_5678,
                             1'b1, 1'b1, 1'b1,
                             64'h0000_0000_1234_5678);
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      mem_rsp_cacheable = 1'b1;
      tb_check32("R3.1 MMIO ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.1 MMIO IQ drains", {28'b0, issue_count}, 32'd0);
      $display("[R3P1-SWAPPED-FINAL-IO] unknown request + exact owner release PASS");
      reset_dut();
    end
  endtask


  // T3U：queue-head CSR 模式下，任何非 ROB-head memory 都必须留在 IQ。
  // 用已完成但被 commit_ready 挡在 ROB head 的 ALU 制造最小反例；这与
  // “较老已完成 CSR 等 mem_idle、较年轻 load 占 reservation”的互等窗口

  // R3.1 long-latency proof: a real 32-iteration DIVU holds the old ROB head
  // while exactly eight independent younger ALUs leave the IQ and reach
  // formal WB.  Retirement must then flatten in original program order.
  task automatic run_r3p1_divu_eight_younger_contract;
    localparam [`XLEN-1:0] OLD_PC = 64'h0000_0000_8000_6e20;
    localparam [`XLEN-1:0] YOUNGER_PC = 64'h0000_0000_8000_6e40;
    reg [ROB_INDEX_W-1:0] old_rob;
    reg [ROB_INDEX_W-1:0] first_younger_rob;
    reg [7:0] younger_wb_mask;
    reg [`XLEN-1:0] expected_commit_pc;
    integer younger_i;
    integer cycle_count;
    integer younger_wb_count;
    integer old_wb_count;
    integer commit_seen;
    integer wb_delta;
    begin
      reset_dut();

      // Seed UINT64_MAX / 3 in architectural x1/x2 so DIVU takes the iterative
      // path rather than the divide-by-zero fast terminal.
      set_dispatch0(32'h8000_6e00,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'hffff_ffff_ffff_ffff);
      set_dispatch1(32'h8000_6e04,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'd3);
      tick_dispatch_to_commit("R3.1 DIVU operand setup",
                              64'hffff_ffff_ffff_ffff, 64'd3);

      set_dispatch0(OLD_PC[31:0], make_muldiv_ctrl(),
                    5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd2, 5'd1,
                               3'b101, 5'd9);
      #1;
      tb_check1("R3.1 DIVU old dispatch ready", dispatch0_ready, 1'b1);
      old_rob = dut.dispatch0_rob_idx_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("R3.1 DIVU old selected", dut.issue0_valid_w, 1'b1);
      tb_check32("R3.1 DIVU old PC", dut.issue0_pc_w[31:0], OLD_PC[31:0]);
      `TB_TICK(clk);
      #1;
      tb_check1("R3.1 DIVU request buffered",
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);

      // Feed eight independent younger ALUs at the architectural two-wide
      // rate while observing issue/WB/retirement in the same loop.  No
      // internal ready/valid boundary is forced apart.
      younger_wb_mask = 8'h00;
      younger_wb_count = 0;
      old_wb_count = 0;
      commit_seen = 0;
      cycle_count = 0;
      younger_i = 0;
      #1;
      while ((commit_seen < 9) && (cycle_count < 80)) begin
        if (younger_i < 8) begin
          set_dispatch0(YOUNGER_PC[31:0] + (younger_i * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd10 + younger_i,
                        64'h100 + younger_i);
          set_dispatch1(YOUNGER_PC[31:0] + ((younger_i + 1) * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd11 + younger_i,
                        64'h101 + younger_i);
          #1;
          tb_check1("R3.1 DIVU younger dispatch0 ready",
                    dispatch0_ready, 1'b1);
          tb_check1("R3.1 DIVU younger dispatch1 ready",
                    dispatch1_ready, 1'b1);
          if (younger_i == 0)
            first_younger_rob = dut.dispatch0_rob_idx_w;
        end

        if (dut.wb0_valid_w) begin
          wb_delta = dut.wb0_rob_idx_w - first_younger_rob;
          if ((wb_delta >= 0) && (wb_delta < 8)) begin
            if (younger_wb_mask[wb_delta])
              $display("[R3P1-DIVU-DUP-WB] cycle=%0d lane=0 rob=%0d delta=%0d",
                       cycle_count, dut.wb0_rob_idx_w, wb_delta);
            tb_check1("R3.1 no repeated younger WB on terminal0",
                      younger_wb_mask[wb_delta], 1'b0);
            younger_wb_mask[wb_delta] = 1'b1;
            younger_wb_count = younger_wb_count + 1;
          end
        end
        if (dut.wb1_valid_w) begin
          wb_delta = dut.wb1_rob_idx_w - first_younger_rob;
          if ((wb_delta >= 0) && (wb_delta < 8)) begin
            if (younger_wb_mask[wb_delta])
              $display("[R3P1-DIVU-DUP-WB] cycle=%0d lane=1 rob=%0d delta=%0d",
                       cycle_count, dut.wb1_rob_idx_w, wb_delta);
            tb_check1("R3.1 no repeated younger WB on terminal1",
                      younger_wb_mask[wb_delta], 1'b0);
            younger_wb_mask[wb_delta] = 1'b1;
            younger_wb_count = younger_wb_count + 1;
          end
        end

        if ((dut.wb0_valid_w && (dut.wb0_rob_idx_w == old_rob)) ||
            (dut.wb1_valid_w && (dut.wb1_rob_idx_w == old_rob))) begin
          old_wb_count = old_wb_count + 1;
          tb_check32("R3.1 all eight WB before old DIVU",
                     {24'b0, younger_wb_mask}, 32'h0000_00ff);
          tb_check1("R3.1 old DIVU formal WB has no same-cycle retire",
                    commit0_valid || commit1_valid, 1'b0);
        end

        if (old_wb_count == 0)
          tb_check1("R3.1 no younger retirement before old DIVU WB",
                    commit0_valid || commit1_valid, 1'b0);

        if (commit0_valid) begin
          expected_commit_pc = (commit_seen == 0) ? OLD_PC :
              (YOUNGER_PC + ((commit_seen - 1) * 4));
          tb_check32("R3.1 flattened commit0 program order",
                     commit0_pc[31:0], expected_commit_pc[31:0]);
          commit_seen = commit_seen + 1;
        end
        if (commit1_valid) begin
          expected_commit_pc = (commit_seen == 0) ? OLD_PC :
              (YOUNGER_PC + ((commit_seen - 1) * 4));
          tb_check32("R3.1 flattened commit1 program order",
                     commit1_pc[31:0], expected_commit_pc[31:0]);
          commit_seen = commit_seen + 1;
        end

        `TB_TICK(clk);
        clear_dispatch();
        if (younger_i < 8)
          younger_i = younger_i + 2;
        #1;
        cycle_count = cycle_count + 1;
        if ((younger_i == 8) && (cycle_count == 4)) begin
          tb_check32("R3.1 DIVU ROB holds old plus eight",
                     {27'b0, rob_count}, 32'd9);
          tb_check1("R3.1 DIVU remains in iterative run",
                    dut.u_muldiv_unit.state_q == 3'd3, 1'b1);
        end
      end

      tb_check32("R3.1 DIVU younger distinct WB mask",
                 {24'b0, younger_wb_mask}, 32'h0000_00ff);
      tb_check32("R3.1 DIVU younger WB exactly once",
                 younger_wb_count, 32'd8);
      tb_check32("R3.1 DIVU old WB exactly once", old_wb_count, 32'd1);
      tb_check32("R3.1 DIVU ordered commit count", commit_seen, 32'd9);
      tb_check32("R3.1 DIVU ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("R3.1 DIVU IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("R3.1 DIVU free-list recovers",
                 {25'b0, free_count}, 32'd32);
      $display("[R3P1-DIVU-8-YOUNGER] cycles=%0d mask=%02h commits=%0d PASS",
               cycle_count, younger_wb_mask, commit_seen);
      reset_dut();
    end
  endtask

  // 具有相同 admission 前件。
  task automatic run_t3u_csr_queue_head_mem_admission;
    integer wait_cycles;
    begin
      if (`OOO_CSR_QUEUE_HEAD) begin
        reset_dut();
        mem_req_ready = 1'b0;
        commit_ready = 1'b0;

        set_dispatch0(32'h8000_6e00,
                      make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                      5'd0, 5'd0, 5'd3, 64'd1);
        #1;
        tb_check1("T3U CSR-QH older done uop dispatch ready",
                  dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        `TB_TICK(clk);
        #1;
        `TB_TICK(clk);
        #1;
        tb_check32("T3U CSR-QH older done uop leaves IQ",
                   {28'b0, issue_count}, 32'd0);
        tb_check32("T3U CSR-QH older done uop remains ROB head",
                   {27'b0, rob_count}, 32'd1);
        tb_check32("T3U CSR-QH older done uop is head zero",
                   {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w}, 32'd0);

        set_dispatch0(32'h8000_6e04,
                      make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                      5'd0, 5'd0, 5'd7, 64'h8000_0360);
        #1;
        tb_check1("T3U CSR-QH younger load dispatch ready",
                  dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        tb_check1("T3U CSR-QH younger load is IQ oldest",
                  dut.iq_issue0_mem_class_w, 1'b1);
        tb_check1("T3U CSR-QH younger load is not ROB head",
                  dut.iq_issue0_rob_idx_w != dut.rob_head_idx_w, 1'b1);
        tb_check1("T3U CSR-QH non-head load admission closes",
                  dut.mem_issue_res_admit_w, 1'b0);
        tb_check1("T3U CSR-QH non-head load cannot capture",
                  dut.mem_issue_res_capture_w, 1'b0);
        tb_check1("T3U CSR-QH reservation stays idle",
                  dut.mem_issue_res_valid_q, 1'b0);
        tb_check1("T3U CSR-QH mem_idle remains available to older head",
                  dut.mem_idle_o, 1'b1);

        commit_ready = 1'b1;
        wait_cycles = 0;
        while (!dut.mem_issue_res_capture_w && (wait_cycles < 100)) begin
          `TB_TICK(clk);
          #1;
          wait_cycles = wait_cycles + 1;
        end
        tb_check1("T3U CSR-QH load eventually captures at ROB head",
                  dut.mem_issue_res_capture_w, 1'b1);
        tb_check1("T3U CSR-QH eventual capture sees ROB head",
                  dut.iq_issue0_rob_idx_w == dut.rob_head_idx_w, 1'b1);
        tb_check1("T3U CSR-QH eventual capture has valid ROB head",
                  dut.rob_head_valid_w, 1'b1);
        $display("[T3U-CSR-QH-MEM-ADMISSION] wait=%0d raw_rob=%0d head=%0d idle=%0b",
                 wait_cycles, dut.iq_issue0_rob_idx_w,
                 dut.rob_head_idx_w, dut.mem_idle_o);
        reset_dut();
      end
    end
  endtask

`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
  // Historical defect backfill for serialize-at-retire Phase1 §10.4.
  //
  // This is an IntBackend boundary experiment, not a claim that the product
  // frontend can dispatch a younger uop after a queue-head CSR.  The exact
  // dual-dispatch state isolates the former ROB mem_quiet dependency:
  //   current owner guard: mem_idle=0 while the SQ STORE owner is live;
  //   reconstructed fixed history: transport idle=1, mem_quiet=mem_idle;
  //   reconstructed defect: transport idle=1, mem_quiet also waits SQ empty.
  task automatic run_hist_ser_qh_younger_store_cycle;
    localparam [`XLEN-1:0] CSR_PC =
        64'h0000_0000_8000_6e80;
    localparam [`XLEN-1:0] STORE_PC =
        64'h0000_0000_8000_6e84;
    localparam [`XLEN-1:0] STORE_VA =
        64'h0000_0000_0000_0a80;
    localparam [`XLEN-1:0] STORE_PA =
        64'h0000_0000_9000_0a80;
    integer wait_cycles;
    integer root_window;
    reg [PRODUCER_ID_W-1:0] csr_pid;
    reg [PRODUCER_ID_W-1:0] store_pid;
    reg [4:0] store_token;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;

      set_dispatch0(CSR_PC,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd3, 64'd1);
      // csrrw x3, mscratch, x0: ROB recognizes the architectural CSR from
      // the instruction, while this leaf bench supplies its execution ctrl.
      dispatch0_inst = 32'h3400_11f3;
      set_dispatch1(STORE_PC, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, STORE_VA);
      dispatch1_inst = 32'h0000_3023;  // sd x0,0(x0)
      #1;
      tb_check1("HIST-QH dual dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("HIST-QH dual dispatch1 ready", dispatch1_ready, 1'b1);
      tb_check1("HIST-QH exact CSR lane fires", dut.dispatch0_fire_w,
                1'b1);
      tb_check1("HIST-QH exact STORE lane fires", dut.dispatch1_fire_w,
                1'b1);
      tb_check1("HIST-QH exact one SQ allocation",
                ((dut.sq_alloc0_valid_w && dut.sq_alloc0_ready_w) ^
                 (dut.sq_alloc1_valid_w && dut.sq_alloc1_ready_w)),
                1'b1);
      csr_pid = dut.dispatch0_producer_id_w;
      store_pid = dut.dispatch1_producer_id_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;

      wait_cycles = 0;
      while (!mem_req_valid && (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check1("HIST-QH younger STORE reaches request", mem_req_valid,
                1'b1);
      tb_check1("HIST-QH younger STORE request is probe", mem_req_probe,
                1'b1);
      tb_check1("HIST-QH younger STORE retains write semantics",
                mem_req_write, 1'b1);
      tb_check1("HIST-QH younger STORE request remains killable",
                mem_req_nokill, 1'b0);
      tb_check32("HIST-QH request owner kind is STORE",
                 {30'b0, mem_req_owner_kind},
                 {30'b0, 2'b01});
      store_token = mem_req_owner_token;
      mem_req_ready = 1'b1;
      #1;
      tb_check1("HIST-QH probe request accepts", dut.mem_req_fire_any_w,
                1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = STORE_PA;
      #1;
      tb_check1("HIST-QH probe response ready", mem_rsp_ready, 1'b1);
      tb_check1("HIST-QH probe response fills SQ", dut.sq_fill_valid_w,
                1'b1);
      tb_check1("HIST-QH fill remains a successful probe",
                dut.sq_fill_probe_w, 1'b1);
      tb_check64("HIST-QH SQ receives translated PA",
                 dut.sq_fill_paddr_w, STORE_PA);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      wait_cycles = 0;
      while ((!dut.u_dispatch_backend.u_rob.head0_is_csr_w ||
              (dut.sq_count_w != 1) ||
              (dut.miq_count_w != 0) ||
              dut.mem_pending_q || dut.mem_buffer_valid_q ||
              dut.mem_retry0_valid_q || dut.mem_retry1_valid_q ||
              dut.mem_issue_res_valid_q || dut.mem_issue1_res_valid_q) &&
             (wait_cycles < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end

      tb_check1("HIST-QH ROB head is completed CSR",
                dut.u_dispatch_backend.u_rob.head0_is_csr_w, 1'b1);
      tb_check32("HIST-QH ROB head identity",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.rob_head_producer_id_w},
                 {{(32-PRODUCER_ID_W){1'b0}}, csr_pid});
      tb_check32("HIST-QH younger STORE remains in SQ",
                 {29'b0, dut.sq_count_w}, 32'd1);
      tb_check32("HIST-QH STORE owner count",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd1);
      tb_check1("HIST-QH STORE token remains live",
                dut.mem_owner_live_mask_w[store_token], 1'b1);
      tb_check32("HIST-QH STORE token kind",
                 {30'b0,
                  dut.mem_owner_kind_table_w[store_token*2 +: 2]},
                 {30'b0, 2'b01});
      tb_check32("HIST-QH STORE token ProducerId",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.mem_owner_producer_id_table_w[
                      store_token*PRODUCER_ID_W +: PRODUCER_ID_W]},
                 {{(32-PRODUCER_ID_W){1'b0}}, store_pid});
      tb_check1("HIST-QH STORE token is an SQ holder",
                dut.v8l_sq_owner_token_mask_r[store_token], 1'b1);
      tb_check32("HIST-QH collector pending count",
                 {26'b0, dut.mem_terminal_pending_count_w}, 32'd0);
      tb_check1("HIST-QH retire side is nonquiet",
                dut.mem_retire_quiet_o, 1'b0);
      tb_check32("HIST-QH dispatch0 raw count",
                 hist_qh_dispatch0_fire_count_q, 32'd1);
      tb_check32("HIST-QH dispatch1 raw count",
                 hist_qh_dispatch1_fire_count_q, 32'd1);
      tb_check32("HIST-QH SQ allocation raw count",
                 hist_qh_sq_alloc_fire_count_q, 32'd1);
      tb_check32("HIST-QH probe request raw count",
                 hist_qh_probe_req_fire_count_q, 32'd1);
      tb_check32("HIST-QH probe response raw count",
                 hist_qh_probe_rsp_fire_count_q, 32'd1);
      tb_check32("HIST-QH no physical write before root window",
                 hist_qh_phys_write_fire_count_q, 32'd0);

      $display("[HIST-SER-QH-YOUNGER-STORE][ROOT] csr_pid=%0d store_pid=%0d token=%0d sq_count=%0d owner_live=%0d terminal_pending=%0d mem_idle=%0b mem_retire_quiet=%0b",
               csr_pid, store_pid, store_token, dut.sq_count_w,
               dut.mem_owner_live_count_w,
               dut.mem_terminal_pending_count_w,
               dut.mem_idle_o, dut.mem_retire_quiet_o);

      commit_ready = 1'b1;
      #1;
      root_window = 0;
      while ((hist_qh_c0_barrier_count_q == 0) &&
             (root_window < 4)) begin
        `TB_TICK(clk);
        #1;
        root_window = root_window + 1;
      end

`ifdef HIST_SER_QH_EXPECT_C0
      tb_check1("HIST-QH reconstructed fixed transport idle",
                dut.mem_idle_o, 1'b1);
      tb_check32("HIST-QH reconstructed fixed CSR C0 commit count",
                 hist_qh_c0_commit_count_q, 32'd1);
      tb_check32("HIST-QH reconstructed fixed CSR C0 barrier count",
                 hist_qh_c0_barrier_count_q, 32'd1);
      tb_check32("HIST-QH C0 cannot write younger STORE",
                 hist_qh_phys_write_fire_count_q, 32'd0);
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      wait_cycles = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check32("HIST-QH C1 flush count",
                 hist_qh_c1_flush_count_q, 32'd1);
      tb_check32("HIST-QH C1 clears younger SQ",
                 {29'b0, dut.sq_count_w}, 32'd0);
      tb_check32("HIST-QH C1 clears younger ROB",
                 {27'b0, rob_count}, 32'd0);
      tb_check32("HIST-QH C1 releases STORE owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      `TB_TICK(clk);
      #1;
      tb_check32("HIST-QH C2 has no repeated CSR C0",
                 hist_qh_c0_barrier_count_q, 32'd1);
      tb_check32("HIST-QH C2 has no physical STORE write",
                 hist_qh_phys_write_fire_count_q, 32'd0);
      $display("[HIST-SER-QH-YOUNGER-STORE][HISTORICAL-FIXED-PASS] root_window=%0d C0=1 C1=1 C2_quiet=1 physical_write=0",
               root_window);
`elsif HIST_SER_QH_EXPECT_CYCLE
      if ((hist_qh_c0_commit_count_q != 0) ||
          (hist_qh_c0_barrier_count_q != 0) ||
          (dut.mem_idle_o !== 1'b1) ||
          (dut.mem_retire_quiet_o !== 1'b0) ||
          (dut.u_dispatch_backend.u_rob.head0_csr_mem_hold_w !== 1'b1) ||
          (dut.sq_count_w != 1) ||
          (dut.mem_owner_live_count_w != 1) ||
          (hist_qh_phys_write_fire_count_q != 0)) begin
        $display("[HIST-SER-QH-YOUNGER-STORE][SETUP-FAIL] root_window=%0d C0_commit=%0d C0_barrier=%0d mem_idle=%0b mem_retire_quiet=%0b hold=%0b sq_count=%0d owner_live=%0d physical_write=%0d",
                 root_window, hist_qh_c0_commit_count_q,
                 hist_qh_c0_barrier_count_q, dut.mem_idle_o,
                 dut.mem_retire_quiet_o,
                 dut.u_dispatch_backend.u_rob.head0_csr_mem_hold_w,
                 dut.sq_count_w, dut.mem_owner_live_count_w,
                 hist_qh_phys_write_fire_count_q);
        $finish_and_return(2);
      end
      $display("[HIST-SER-QH-YOUNGER-STORE][EXPECTED-FAIL] root_window=%0d C0=0 mem_idle=1 mem_retire_quiet=0 hold=1 sq_count=1 owner_live=1 physical_write=0",
               root_window);
      $finish_and_return(1);
`else
      tb_check1("HIST-QH current owner guard keeps mem_idle low",
                dut.mem_idle_o, 1'b0);
      tb_check32("HIST-QH current owner guard blocks CSR C0 commit",
                 hist_qh_c0_commit_count_q, 32'd0);
      tb_check32("HIST-QH current owner guard blocks CSR C0 barrier",
                 hist_qh_c0_barrier_count_q, 32'd0);
      tb_check1("HIST-QH current hold is owner-live sensitive",
                dut.u_dispatch_backend.u_rob.head0_csr_mem_hold_w, 1'b1);
      tb_check32("HIST-QH current guard emits no physical write",
                 hist_qh_phys_write_fire_count_q, 32'd0);
      $display("[HIST-SER-QH-YOUNGER-STORE][CURRENT-OWNER-GUARD-PASS] root_window=%0d C0=0 mem_idle=0 mem_retire_quiet=0 owner_live=1 sq_count=1 physical_write=0",
               root_window);
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      wait_cycles = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_cycles < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_cycles = wait_cycles + 1;
      end
      tb_check32("HIST-QH current cleanup clears younger SQ",
                 {29'b0, dut.sq_count_w}, 32'd0);
      tb_check32("HIST-QH current cleanup releases STORE owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
`endif
    end
  endtask
`endif

  // P0-A focused truth table: no clock edge is taken while internal owners are
  // forced, so this probes only the combinational write-enable topology and
  // cannot create a synthetic ROB completion.  Both physical WB lanes cover
  // all five sources at nonzero/p0 destinations; FPWB also keeps rd-disable
  // separate from p0 so either gate cannot hide a regression in the other.
`ifdef OOO_ASSERT
  task automatic run_p0_wb_write_valid_source_matrix;
    begin
      tb_check1("P0-A idle wb0 write invalid", dut.gpr_wb0_write_valid_w,
                1'b0);
      tb_check1("P0-A idle wb1 write invalid", dut.gpr_wb1_write_valid_w,
                1'b0);

      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_pdest_q = 6'd1;
      #1;
      tb_check1("P0-A wb0 EX source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 EX legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      release dut.ex0_valid_q;
      release dut.ex0_pdest_q;
      #1;

      force dut.mem_wb0_valid_w = 1'b1;
      force dut.mem_rsp_int_pdest_w = 6'd2;
      #1;
      tb_check1("P0-A wb0 MEM source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 MEM legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.mem_rsp_int_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 MEM p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 MEM p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.mem_wb0_valid_w;
      release dut.mem_rsp_int_pdest_w;
      #1;

      force dut.muldiv_wb0_valid_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd3;
      #1;
      tb_check1("P0-A wb0 MULDIV source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 MULDIV legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.muldiv_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 MULDIV p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 MULDIV p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.muldiv_wb0_valid_w;
      release dut.muldiv_resp_pdest_w;
      #1;

      force dut.clmul_wb0_valid_w = 1'b1;
      force dut.clmul_resp_pdest_w = 6'd4;
      #1;
      tb_check1("P0-A wb0 CLMUL source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 CLMUL legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.clmul_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 CLMUL p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 CLMUL p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.clmul_wb0_valid_w;
      release dut.clmul_resp_pdest_w;
      #1;

      force dut.fpwb_wb0_valid_w = 1'b1;
      force dut.fpwb_rd_en_w = 1'b1;
      force dut.fpwb_pdest_w = 6'd5;
      #1;
      tb_check1("P0-A wb0 FPWB source", dut.gpr_wb0_write_valid_w, 1'b1);
      tb_check1("P0-A wb0 FPWB legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b1);
      force dut.fpwb_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 FPWB p0 rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 FPWB p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      force dut.fpwb_pdest_w = 6'd5;
      force dut.fpwb_rd_en_w = 1'b0;
      #1;
      tb_check1("P0-A wb0 FPWB rd-disable rejects write",
                dut.gpr_wb0_write_valid_w, 1'b0);
      tb_check1("P0-A wb0 FPWB rd-disable legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.fpwb_wb0_valid_w;
      release dut.fpwb_rd_en_w;
      release dut.fpwb_pdest_w;
      #1;

      force dut.ex0_wb_valid_w = 1'b1;
      force dut.ex0_pdest_q = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb0 p0 rejects write", dut.gpr_wb0_write_valid_w,
                1'b0);
      tb_check1("P0-A wb0 EX p0 legacy equivalence",
                dut.gpr_wb0_legacy_write_valid_w, 1'b0);
      release dut.ex0_wb_valid_w;
      release dut.ex0_pdest_q;
      #1;

      force dut.ex1_wb_valid_w = 1'b1;
      force dut.ex1_pdest_q = 6'd6;
      #1;
      tb_check1("P0-A wb1 EX source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 EX legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      release dut.ex1_wb_valid_w;
      release dut.ex1_pdest_q;
      #1;

      force dut.mem_wb1_valid_w = 1'b1;
      force dut.mem_rsp_int_pdest_w = 6'd7;
      #1;
      tb_check1("P0-A wb1 MEM source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 MEM legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.mem_rsp_int_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 MEM p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 MEM p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.mem_wb1_valid_w;
      release dut.mem_rsp_int_pdest_w;
      #1;

      force dut.muldiv_wb1_valid_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd8;
      #1;
      tb_check1("P0-A wb1 MULDIV source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 MULDIV legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.muldiv_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 MULDIV p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 MULDIV p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.muldiv_wb1_valid_w;
      release dut.muldiv_resp_pdest_w;
      #1;

      force dut.clmul_wb1_valid_w = 1'b1;
      force dut.clmul_resp_pdest_w = 6'd9;
      #1;
      tb_check1("P0-A wb1 CLMUL source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 CLMUL legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.clmul_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 CLMUL p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 CLMUL p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.clmul_wb1_valid_w;
      release dut.clmul_resp_pdest_w;
      #1;

      force dut.fpwb_wb1_valid_w = 1'b1;
      force dut.fpwb_rd_en_w = 1'b1;
      force dut.fpwb_pdest_w = 6'd10;
      #1;
      tb_check1("P0-A wb1 FPWB source", dut.gpr_wb1_write_valid_w, 1'b1);
      tb_check1("P0-A wb1 FPWB legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b1);
      force dut.fpwb_pdest_w = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 FPWB p0 rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 FPWB p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      force dut.fpwb_pdest_w = 6'd10;
      force dut.fpwb_rd_en_w = 1'b0;
      #1;
      tb_check1("P0-A wb1 FPWB rd-disable rejects write",
                dut.gpr_wb1_write_valid_w, 1'b0);
      tb_check1("P0-A wb1 FPWB rd-disable legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.fpwb_wb1_valid_w;
      release dut.fpwb_rd_en_w;
      release dut.fpwb_pdest_w;
      #1;

      force dut.ex1_wb_valid_w = 1'b1;
      force dut.ex1_pdest_q = {PHY_REG_ADDR_W{1'b0}};
      #1;
      tb_check1("P0-A wb1 p0 rejects write", dut.gpr_wb1_write_valid_w,
                1'b0);
      tb_check1("P0-A wb1 EX p0 legacy equivalence",
                dut.gpr_wb1_legacy_write_valid_w, 1'b0);
      release dut.ex1_wb_valid_w;
      release dut.ex1_pdest_q;
      #1;

      $display("[P0-A-WB-VALID-SOURCE-MATRIX] 22/22 PASS: 2 lanes x (5 nonzero + 5 p0), plus 2 FP rd-disable");
    end
  endtask
`endif

  // v8h: ROB exact-open is an edge-old observation.  These directed windows
  // independently drive raw source facts and verify that only the fixed
  // full-PID claim chain controls actual WB/public completion.  No force is
  // applied to the gates under test.
  task run_v8h_longop_same_edge_claim_matrix;
    reg [PRODUCER_ID_W-1:0] pid_a;
    reg [PRODUCER_ID_W-1:0] pid_b;
    begin
      reset_dut();
      pid_a = {{PRODUCER_GEN_W{1'b1}}, 4'h2};
      pid_b = {{(PRODUCER_GEN_W-1){1'b1}}, 1'b0, 4'h3};

      // Exercise the real owner-output -> onehot -> union -> indexed dispatch
      // path.  The mask itself is not forced.
      set_dispatch0(64'h8000_1800,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                  1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd18, 64'd1);
      #1;
      pid_a = dut.dispatch0_producer_id_w;
      tb_check1("v8h lease baseline dispatch ready", dispatch0_ready, 1'b1);
      force dut.muldiv_owner_valid_w = 1'b1;
      force dut.muldiv_owner_producer_id_w = pid_a;
      #1;
      tb_check1("v8h MulDiv lease reaches union",
                dut.producer_live_mask_w[pid_a], 1'b1);
      tb_check1("v8h MulDiv lease stalls matching birth",
                dispatch0_ready, 1'b0);
      release dut.muldiv_owner_valid_w;
      release dut.muldiv_owner_producer_id_w;
      #1;
      force dut.clmul_owner_valid_w = 1'b1;
      force dut.clmul_owner_producer_id_w = pid_a;
      #1;
      tb_check1("v8h CLMUL lease reaches union",
                dut.producer_live_mask_w[pid_a], 1'b1);
      tb_check1("v8h CLMUL lease stalls matching birth",
                dispatch0_ready, 1'b0);
      release dut.clmul_owner_valid_w;
      release dut.clmul_owner_producer_id_w;
      clear_dispatch();
      #1;

      // EX0 > EX1 for one full PID; physical lane1 remains occupied but has
      // no actual completion.
      force dut.ex0_pre_auth_valid_w = 1'b1;
      force dut.ex1_pre_auth_valid_w = 1'b1;
      force dut.ex0_producer_open_w = 1'b1;
      force dut.ex1_producer_open_w = 1'b1;
      force dut.ex0_producer_id_q = pid_a;
      force dut.ex1_producer_id_q = pid_a;
      #1;
      tb_check1("v8h same PID EX0 claims", dut.ex0_wb_valid_w, 1'b1);
      tb_check1("v8h same PID EX1 is fenced", dut.ex1_wb_valid_w, 1'b0);
      tb_check1("v8h same PID EX public lane0 only", dut.wb0_valid_w, 1'b1);
      tb_check1("v8h same PID EX public lane1 closed", dut.wb1_valid_w, 1'b0);
      release dut.ex0_pre_auth_valid_w;
      release dut.ex1_pre_auth_valid_w;
      release dut.ex0_producer_open_w;
      release dut.ex1_producer_open_w;
      release dut.ex0_producer_id_q;
      release dut.ex1_producer_id_q;
      #1;

      // EX0 actual claim suppresses MulDiv side effects, while the raw
      // response still owns the remaining transport slot and drains.
      force dut.ex0_pre_auth_valid_w = 1'b1;
      force dut.ex0_producer_open_w = 1'b1;
      force dut.ex0_producer_id_q = pid_a;
      force dut.muldiv_resp_valid_w = 1'b1;
      force dut.muldiv_resp_producer_id_w = pid_a;
      force dut.muldiv_completion_rob_open_w = 1'b1;
      force dut.muldiv_resp_pdest_w = 6'd20;
      #1;
      tb_check1("v8h EX0/MulDiv raw response drains",
                dut.muldiv_resp_ready_w, 1'b1);
      tb_check1("v8h EX0/MulDiv authorization fenced",
                dut.muldiv_completion_authorized_w, 1'b0);
      tb_check1("v8h EX0/MulDiv no longop actual WB",
                dut.muldiv_actual_claim_w, 1'b0);
      tb_check1("v8h EX0/MulDiv public lane1 closed", dut.wb1_valid_w, 1'b0);
      release dut.ex0_pre_auth_valid_w;
      release dut.ex0_producer_open_w;
      release dut.ex0_producer_id_q;
      release dut.muldiv_resp_valid_w;
      release dut.muldiv_resp_producer_id_w;
      release dut.muldiv_completion_rob_open_w;
      release dut.muldiv_resp_pdest_w;
      #1;

      // EX1 actual claim suppresses CLMUL on the other physical WB lane.
      force dut.ex1_pre_auth_valid_w = 1'b1;
      force dut.ex1_producer_open_w = 1'b1;
      force dut.ex1_producer_id_q = pid_a;
      force dut.clmul_resp_valid_w = 1'b1;
      force dut.clmul_resp_producer_id_w = pid_a;
      force dut.clmul_completion_rob_open_w = 1'b1;
      force dut.clmul_resp_pdest_w = 6'd21;
      #1;
      tb_check1("v8h EX1/CLMUL raw response drains",
                dut.clmul_resp_ready_w, 1'b1);
      tb_check1("v8h EX1/CLMUL authorization fenced",
                dut.clmul_completion_authorized_w, 1'b0);
      tb_check1("v8h EX1/CLMUL public lane0 closed", dut.wb0_valid_w, 1'b0);
      tb_check1("v8h EX1/CLMUL public lane1 is EX", dut.wb1_valid_w, 1'b1);
      release dut.ex1_pre_auth_valid_w;
      release dut.ex1_producer_open_w;
      release dut.ex1_producer_id_q;
      release dut.clmul_resp_valid_w;
      release dut.clmul_resp_producer_id_w;
      release dut.clmul_completion_rob_open_w;
      release dut.clmul_resp_pdest_w;
      #1;

      // Memory is the next actual claimant.  Test MulDiv and CLMUL
      // independently so each raw response has a transport slot.
      force dut.mem_wb_fire_w = 1'b1;
      force dut.mem_completion_producer_id_w = pid_a;
      force dut.muldiv_resp_valid_w = 1'b1;
      force dut.muldiv_resp_producer_id_w = pid_a;
      force dut.muldiv_completion_rob_open_w = 1'b1;
      #1;
      tb_check1("v8h memory/MulDiv raw response drains",
                dut.muldiv_resp_ready_w, 1'b1);
      tb_check1("v8h memory/MulDiv actual fenced",
                dut.muldiv_actual_claim_w, 1'b0);
      tb_check1("v8h memory/MulDiv public memory only",
                dut.wb0_valid_w && !dut.wb1_valid_w, 1'b1);
      release dut.muldiv_resp_valid_w;
      release dut.muldiv_resp_producer_id_w;
      release dut.muldiv_completion_rob_open_w;
      #1;
      force dut.clmul_resp_valid_w = 1'b1;
      force dut.clmul_resp_producer_id_w = pid_a;
      force dut.clmul_completion_rob_open_w = 1'b1;
      #1;
      tb_check1("v8h memory/CLMUL raw response drains",
                dut.clmul_resp_ready_w, 1'b1);
      tb_check1("v8h memory/CLMUL actual fenced",
                dut.clmul_wb0_valid_w || dut.clmul_wb1_valid_w, 1'b0);
      tb_check1("v8h memory/CLMUL public memory only",
                dut.wb0_valid_w && !dut.wb1_valid_w, 1'b1);
      release dut.mem_wb_fire_w;
      release dut.mem_completion_producer_id_w;
      release dut.clmul_resp_valid_w;
      release dut.clmul_resp_producer_id_w;
      release dut.clmul_completion_rob_open_w;
      #1;

      // MulDiv > CLMUL for equal PID.  Both raw responses drain through two
      // slots, but only MulDiv becomes an actual completion.
      force dut.muldiv_resp_valid_w = 1'b1;
      force dut.muldiv_resp_producer_id_w = pid_a;
      force dut.muldiv_completion_rob_open_w = 1'b1;
      force dut.clmul_resp_valid_w = 1'b1;
      force dut.clmul_resp_producer_id_w = pid_a;
      force dut.clmul_completion_rob_open_w = 1'b1;
      #1;
      tb_check1("v8h equal longops MulDiv raw drains",
                dut.muldiv_resp_ready_w, 1'b1);
      tb_check1("v8h equal longops CLMUL raw drains",
                dut.clmul_resp_ready_w, 1'b1);
      tb_check1("v8h equal longops MulDiv actual",
                dut.muldiv_actual_claim_w, 1'b1);
      tb_check1("v8h equal longops CLMUL fenced",
                dut.clmul_wb0_valid_w || dut.clmul_wb1_valid_w, 1'b0);
      tb_check1("v8h equal longops one public completion",
                dut.wb0_valid_w && !dut.wb1_valid_w, 1'b1);

      // Changing only the lower-priority PID permits two independent actual
      // completions in the same cycle.
      force dut.clmul_resp_producer_id_w = pid_b;
      #1;
      tb_check1("v8h different longops MulDiv actual",
                dut.muldiv_actual_claim_w, 1'b1);
      tb_check1("v8h different longops CLMUL actual",
                dut.clmul_wb0_valid_w || dut.clmul_wb1_valid_w, 1'b1);
      tb_check1("v8h different longops dual public completion",
                dut.wb0_valid_w && dut.wb1_valid_w, 1'b1);

      // A stale high-priority MulDiv may consume transport but cannot suppress
      // an exact lower-priority CLMUL with another PID.
      force dut.muldiv_completion_rob_open_w = 1'b0;
      #1;
      tb_check1("v8h stale MulDiv still drains", dut.muldiv_resp_ready_w, 1'b1);
      tb_check1("v8h stale MulDiv has no actual", dut.muldiv_actual_claim_w, 1'b0);
      tb_check1("v8h exact CLMUL behind stale MulDiv completes",
                dut.clmul_wb0_valid_w || dut.clmul_wb1_valid_w, 1'b1);
      tb_check1("v8h stale/exact longops one public completion",
                !dut.wb0_valid_w && dut.wb1_valid_w, 1'b1);
      release dut.muldiv_resp_valid_w;
      release dut.muldiv_resp_producer_id_w;
      release dut.muldiv_completion_rob_open_w;
      release dut.clmul_resp_valid_w;
      release dut.clmul_resp_producer_id_w;
      release dut.clmul_completion_rob_open_w;
      #1;

      // A stale CLMUL remains a pure transport occupant; the second slot lets
      // an independently authorized FP formal token progress.
      force dut.clmul_resp_valid_w = 1'b1;
      force dut.clmul_resp_producer_id_w = pid_a;
      force dut.clmul_completion_rob_open_w = 1'b0;
      force dut.fpwb_valid_w = 1'b1;
      force dut.fpwb_producer_id_w = pid_b;
      force dut.fpwb_completion_authorized_w = 1'b1;
      #1;
      tb_check1("v8h stale CLMUL drains before FP", dut.clmul_resp_ready_w, 1'b1);
      tb_check1("v8h stale CLMUL public lane closed", dut.wb0_valid_w, 1'b0);
      tb_check1("v8h exact FP uses remaining lane", dut.wb1_valid_w, 1'b1);
      release dut.clmul_resp_valid_w;
      release dut.clmul_resp_producer_id_w;
      release dut.clmul_completion_rob_open_w;
      release dut.fpwb_valid_w;
      release dut.fpwb_producer_id_w;
      release dut.fpwb_completion_authorized_w;
      #1;

      $display("[V8H-LONGOP-SAME-EDGE-CLAIM] EX/memory/MulDiv/CLMUL/FP matrix PASS");
      reset_dut();
    end
  endtask

  // v8i: build a real nine-op FP backlog while both raw FP formal routes are
  // blocked.  Eight operations may own post-launch completion credit; the
  // ninth must remain losslessly in the issue packet.  An occupied FIFO token
  // is then used to inject the reviewer's delayed EX0(P) and second FP(P)
  // counterexamples before normal formal drain resumes.
  task run_v8i_fp_pending_owner_and_credit;
    integer op;
    integer guard;
    integer hold_cycle;
    reg [PRODUCER_ID_W-1:0] pending_pid;
    reg [FP_ISSUE_PACKET_W-1:0] held_packet;
    begin
      reset_dut();
      force dut.fpwb_to_wb0_w = 1'b0;
      force dut.fpwb_to_wb1_w = 1'b0;

      for (op = 0; op < 9; op = op + 1) begin
        set_fp_binary0(64'h8000_3000 + (op * 4),
                       7'b0000001, 5'd0, 5'd0, op + 1, 1'b1);
        #1;
        tb_check1("V8I nine-op FP dispatch ready", dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        #1;
      end

      guard = 0;
      while (!((dut.u_fp_backend.execution_credit_used_w == 5'd8) &&
               dut.u_fp_backend.fp_issue_stage_valid_w) &&
             (guard < 48)) begin
        `TB_TICK(clk);
        #1;
        guard = guard + 1;
      end
      tb_check32("V8I post-launch credit saturates at eight",
                 {27'b0, dut.u_fp_backend.execution_credit_used_w}, 32'd8);
      tb_check1("V8I ninth op remains in issue packet",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      tb_check1("V8I saturated credit closes execution launch",
                dut.u_fp_backend.execution_credit_open_w, 1'b0);
      held_packet = dut.u_fp_backend.fp_issue_stage_down_payload_w;

      // Let all eight already-launched operations reach FIFO.  No formal pop
      // is possible and the ninth packet must remain bit-for-bit stable.
      guard = 0;
      while ((dut.u_fp_backend.done_fifo_count_q != 4'd8) &&
             (guard < 48)) begin
        `TB_TICK(clk);
        #1;
        tb_check1("V8I saturated packet remains valid",
                  dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
        tb_check_fp_issue_packet("V8I saturated packet remains stable",
                                 dut.u_fp_backend.fp_issue_stage_down_payload_w,
                                 held_packet);
        tb_check1("V8I FIFO never exceeds physical depth",
                  dut.u_fp_backend.done_fifo_count_q <= 4'd8, 1'b1);
        tb_check32("V8I credit remains exactly eight while blocked",
                   {27'b0, dut.u_fp_backend.execution_credit_used_w}, 32'd8);
        guard = guard + 1;
      end
      tb_check32("V8I eight launched results all have FIFO tokens",
                 {28'b0, dut.u_fp_backend.done_fifo_count_q}, 32'd8);
      tb_check1("V8I FIFO head is raw-valid while transport blocked",
                dut.fpwb_valid_w, 1'b1);
      pending_pid = dut.fpwb_producer_id_w;
      tb_check1("V8I FIFO head owns pending capability",
                dut.fp_completion_pending_mask_w[pending_pid], 1'b1);
      tb_check1("V8I pending capability is also a dispatch lease",
                dut.fp_producer_live_mask_w[pending_pid], 1'b1);
      tb_check1("V8I FP lease participates in global birth fence",
                dut.producer_live_mask_w[pending_pid], 1'b1);

      // A stale/closed formal head still gets a raw route, but actual WB must
      // remain zero.  Re-block routes before any clock edge so the real token
      // stays resident for the delayed-duplicate checks below.
      release dut.fpwb_to_wb0_w;
      release dut.fpwb_to_wb1_w;
      force dut.fp_formal_completion_rob_open_w = 1'b0;
      #1;
      tb_check1("V8I stale formal head still has raw route",
                dut.fpwb_ready_w, 1'b1);
      tb_check1("V8I stale formal head has no actual WB",
                dut.fpwb_actual_claim_w, 1'b0);
      force dut.fpwb_to_wb0_w = 1'b0;
      force dut.fpwb_to_wb1_w = 1'b0;
      release dut.fp_formal_completion_rob_open_w;
      #1;

      // Reviewer counterexample 1a: delayed EX0(P) arrives after the FP result
      // was accepted but before its formal token can pop.
      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_producer_id_q = pending_pid;
      #1;
      tb_check1("V8I delayed EX0 still sees ROB exact-open",
                dut.ex0_producer_open_w, 1'b1);
      tb_check1("V8I delayed EX0 is fenced by pending owner",
                dut.ex0_wb_valid_w, 1'b0);
      tb_check1("V8I delayed EX0 has no public completion",
                dut.execute0_valid_o, 1'b0);
      release dut.ex0_valid_q;
      release dut.ex0_producer_id_q;
      #1;

      // Reviewer counterexample 1b: a second FP candidate(P) is raw-visible,
      // but it cannot write FPR/wake/push another token.
      force dut.u_fp_backend.arith_out_valid_w = 1'b1;
      force dut.u_fp_backend.arith_out_producer_id_w = pending_pid;
      force dut.u_fp_backend.arith_out_rob_w = pending_pid[ROB_INDEX_W-1:0];
      force dut.u_fp_backend.arith_out_pdest_w = 6'd55;
      force dut.u_fp_backend.arith_out_value_w = 64'h4008_0000_0000_0000;
      force dut.u_fp_backend.arith_out_fflags_w = 5'b00000;
      #1;
      tb_check1("V8I duplicate FP candidate still sees ROB exact-open",
                dut.fp_result_completion_rob_open_w, 1'b1);
      tb_check1("V8I duplicate FP candidate is fenced by pending owner",
                dut.fp_result_authorized_w, 1'b0);
      tb_check1("V8I duplicate FP candidate cannot wake FPR",
                dut.fp_wake0_valid_w, 1'b0);
      tb_check1("V8I duplicate FP candidate cannot push FIFO",
                dut.u_fp_backend.df_push_w, 1'b0);
      release dut.u_fp_backend.arith_out_valid_w;
      release dut.u_fp_backend.arith_out_producer_id_w;
      release dut.u_fp_backend.arith_out_rob_w;
      release dut.u_fp_backend.arith_out_pdest_w;
      release dut.u_fp_backend.arith_out_value_w;
      release dut.u_fp_backend.arith_out_fflags_w;
      #1;

      // Backpressure persists for several extra cycles at full occupancy.
      for (hold_cycle = 0; hold_cycle < 4; hold_cycle = hold_cycle + 1) begin
        `TB_TICK(clk);
        #1;
        tb_check32("V8I full FIFO count is stable under backpressure",
                   {28'b0, dut.u_fp_backend.done_fifo_count_q}, 32'd8);
        tb_check_fp_issue_packet("V8I ninth packet survives extended block",
                                 dut.u_fp_backend.fp_issue_stage_down_payload_w,
                                 held_packet);
      end

      release dut.fpwb_to_wb0_w;
      release dut.fpwb_to_wb1_w;
      #1;
      tb_check1("V8I original token alone obtains formal authority",
                dut.fpwb_completion_authorized_w, 1'b1);
      tb_check1("V8I original token has a raw formal route",
                dut.fpwb_ready_w, 1'b1);

      // Conservative credit is edge-old: pop frees the slot at this edge,
      // and the held packet launches only in the following cycle.
      `TB_TICK(clk);
      #1;
      tb_check1("V8I packet holds through credit-release edge",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8I ninth packet launches after registered credit release",
                dut.u_fp_backend.fp_issue_stage_valid_w, 1'b0);

      guard = 0;
      while (((rob_count != {ROB_COUNT_W{1'b0}}) ||
              (dut.u_fp_backend.execution_credit_used_w != 5'd0) ||
              dut.u_fp_backend.fp_issue_stage_valid_w) &&
             (guard < 160)) begin
        `TB_TICK(clk);
        #1;
        tb_check1("V8I drain never exceeds credit depth",
                  dut.u_fp_backend.execution_credit_used_w <= 5'd8, 1'b1);
        guard = guard + 1;
      end
      tb_check32("V8I all nine ROB entries retire",
                 {27'b0, rob_count}, 32'd0);
      tb_check32("V8I all completion credits release",
                 {27'b0, dut.u_fp_backend.execution_credit_used_w}, 32'd0);
      tb_check32("V8I done FIFO drains exactly",
                 {28'b0, dut.u_fp_backend.done_fifo_count_q}, 32'd0);
      $display("[V8I-FP-PENDING-CREDIT] pending-owner and nine-op credit counterexamples PASS");
      reset_dut();
    end
  endtask

  // V8Y OOO-4 control-flow witness.  Keep one older completed ALU in the ROB,
  // then place two independently ready, predicted-wrong branches in the IQ.
  // The balanced selector must expose the older branch A; when A resolves one
  // cycle later, the same-cycle recovery gate must keep younger branch B from
  // issuing or producing a second resolve/BPU-update packet.  D and A are the
  // survivor prefix and must each complete/retire exactly once; B is the
  // wrong-path suffix and must do neither.
  task automatic run_v8y_oldest_control_recovery_case;
    input wrap_case;
    input [`XLEN-1:0] base_pc;
    reg [PRODUCER_ID_W-1:0] survivor_pid;
    reg [PRODUCER_ID_W-1:0] branch_a_pid;
    reg [PRODUCER_ID_W-1:0] branch_b_pid;
    integer survivor_complete_count;
    integer branch_a_complete_count;
    integer branch_b_complete_count;
    integer survivor_retire_count;
    integer branch_a_retire_count;
    integer branch_b_retire_count;
    integer resolve_count;
    integer branch_b_issue_count;
    integer wait_i;
    integer prime_i;
    integer post_recovery_checked;
    begin
      reset_dut();
      commit_ready = 1'b1;
      survivor_complete_count = 0;
      branch_a_complete_count = 0;
      branch_b_complete_count = 0;
      survivor_retire_count = 0;
      branch_a_retire_count = 0;
      branch_b_retire_count = 0;
      resolve_count = 0;
      branch_b_issue_count = 0;
      post_recovery_checked = 0;

      // Seven retired pairs move both ROB head and tail from index 0 to 14.
      // The wrap case then allocates D/A/B at 14/15/0, respectively.  This
      // rejects raw-index ordering while preserving the same full-PID ledger
      // and recovery behavior as the linear 0/1/2 case.
      if (wrap_case) begin
        for (prime_i = 0; prime_i < 7; prime_i = prime_i + 1) begin
          set_dispatch0(64'h0000_0000_8000_7000 + (prime_i * 8),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd10, 64'h100 + prime_i);
          set_dispatch1(64'h0000_0000_8000_7004 + (prime_i * 8),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd11, 64'h200 + prime_i);
          tick_dispatch_to_commit("V8Y wrap prime",
                                  64'h100 + prime_i,
                                  64'h200 + prime_i);
        end
        tb_check32("V8Y wrap head primed to 14",
                   {{(32-ROB_INDEX_W){1'b0}},
                    dut.u_dispatch_backend.u_rob.head_q}, 32'd14);
        tb_check32("V8Y wrap tail primed to 14",
                   {{(32-ROB_INDEX_W){1'b0}},
                    dut.u_dispatch_backend.u_rob.tail_q}, 32'd14);
      end
      commit_ready = 1'b0;

      // D becomes a completed but deliberately unretired prefix entry.  This
      // makes recovery selectivity observable instead of allowing a globally
      // empty prefix to satisfy the test vacuously.
      set_dispatch0(base_pc,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h0000_0000_0000_005a);
      #1;
      tb_check1("V8Y survivor dispatch ready", dispatch0_ready, 1'b1);
      survivor_pid = dispatch0_producer_id;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8Y survivor issues", dut.issue0_fire_w, 1'b1);
      tb_check32("V8Y survivor issue exact PID",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.iq_issue0_producer_id_w},
                 {{(32-PRODUCER_ID_W){1'b0}}, survivor_pid});
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8Y survivor formal completion", dut.wb0_valid_w, 1'b1);
      tb_check1("V8Y survivor completion exact PID",
                dut.wb0_producer_id_w == survivor_pid, 1'b1);
      if (dut.wb0_valid_w && (dut.wb0_producer_id_w == survivor_pid))
        survivor_complete_count = survivor_complete_count + 1;
      tb_check1("V8Y survivor held from retirement", commit0_valid, 1'b0);

      // A and B are both ready and both would mispredict if issued.  Their
      // simultaneous residency is the non-vacuum multiple-control window.
      set_dispatch0(base_pc + 64'h10,
                    make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      set_dispatch1(base_pc + 64'h14,
                    make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_npc = base_pc + 64'h14;
      dispatch1_pred_npc = base_pc + 64'h18;
      dispatch0_bht_idx = 10'h121;
      dispatch1_bht_idx = 10'h2e2;
      #1;
      tb_check1("V8Y branch A dispatch ready", dispatch0_ready, 1'b1);
      tb_check1("V8Y branch B dispatch ready", dispatch1_ready, 1'b1);
      branch_a_pid = dispatch0_producer_id;
      branch_b_pid = dut.dispatch1_producer_id_w;
      tb_check1("V8Y branch identities are distinct",
                branch_a_pid != branch_b_pid, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (dut.wb0_valid_w && (dut.wb0_producer_id_w == survivor_pid))
        survivor_complete_count = survivor_complete_count + 1;
      if (dut.wb1_valid_w && (dut.wb1_producer_id_w == survivor_pid))
        survivor_complete_count = survivor_complete_count + 1;
      tb_check32("V8Y survivor plus two controls in ROB",
                 {27'b0, rob_count}, 32'd3);
      tb_check32("V8Y two controls simultaneously resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("V8Y branch A genuinely ready",
                dut.u_dispatch_backend.u_issue_queue.select_base_ready_w[0],
                1'b1);
      tb_check1("V8Y branch B genuinely ready",
                dut.u_dispatch_backend.u_issue_queue.select_base_ready_w[1],
                1'b1);
      tb_check1("V8Y resident entry0 is branch A",
                dut.u_dispatch_backend.u_issue_queue.ctrl_q[0][`CTRL_BRANCH_BIT],
                1'b1);
      tb_check1("V8Y resident entry1 is branch B",
                dut.u_dispatch_backend.u_issue_queue.ctrl_q[1][`CTRL_BRANCH_BIT],
                1'b1);
      tb_check1("V8Y oldest branch A owns lane0",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      tb_check64("V8Y oldest branch A issue PC", dut.issue0_pc_w,
                 base_pc + 64'h10);
      tb_check32("V8Y oldest branch A issue PID",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.iq_issue0_producer_id_w},
                 {{(32-PRODUCER_ID_W){1'b0}}, branch_a_pid});
      tb_check1("V8Y younger control cannot use lane1",
                dut.issue1_valid_w, 1'b0);

      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (branch_resolve_valid)
        resolve_count = resolve_count + 1;
      if (dut.wb0_valid_w && (dut.wb0_producer_id_w == branch_a_pid))
        branch_a_complete_count = branch_a_complete_count + 1;
      if ((dut.wb0_valid_w && (dut.wb0_producer_id_w == branch_b_pid)) ||
          (dut.wb1_valid_w && (dut.wb1_producer_id_w == branch_b_pid)))
        branch_b_complete_count = branch_b_complete_count + 1;
      if (dut.issue0_ctrlflow_fire_w &&
          (dut.iq_issue0_producer_id_w == branch_b_pid))
        branch_b_issue_count = branch_b_issue_count + 1;
      tb_check1("V8Y branch A resolve valid", branch_resolve_valid, 1'b1);
      tb_check1("V8Y branch A is predicted wrong",
                branch_resolve_mispredict, 1'b1);
      tb_check64("V8Y branch A determines recovery PC",
                 branch_resolve_pc, base_pc + 64'h10);
      tb_check32("V8Y branch A determines recovery boundary",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}},
                  branch_a_pid[ROB_INDEX_W-1:0]});
      tb_check1("V8Y branch A completion survives", dut.wb0_valid_w, 1'b1);
      tb_check1("V8Y branch A completion exact PID",
                dut.wb0_producer_id_w == branch_a_pid, 1'b1);
      tb_check1("V8Y branch A starts ROB recovery",
                dut.u_dispatch_backend.rob_kill_valid_w, 1'b1);
      tb_check32("V8Y younger branch B remains the resident suffix",
                 {28'b0, issue_count}, 32'd1);
      tb_check1("V8Y younger branch B is still a control entry",
                dut.u_dispatch_backend.u_issue_queue.ctrl_q[0][`CTRL_BRANCH_BIT],
                1'b1);
      tb_check1("V8Y recovery cycle closes younger issue valid",
                dut.issue0_valid_w, 1'b0);
      tb_check1("V8Y recovery cycle closes younger control fire",
                dut.issue0_ctrlflow_fire_w, 1'b0);
      tb_check1("V8Y younger branch has no completion",
                branch_b_complete_count != 0, 1'b0);
      tb_check1("V8Y recovery cycle blocks retirement",
                commit0_valid || commit1_valid, 1'b0);

      // The kill edge latches a one-entry ROB walk.  Open retirement while
      // recovery is active; the ROB itself must keep the gate closed until B
      // is gone, then retire only the exact survivor prefix D/A.
      `TB_TICK(clk);
      clear_dispatch();
      commit_ready = 1'b1;
      #1;
      wait_i = 0;
      while (((rob_count != {ROB_COUNT_W{1'b0}}) ||
              dut.u_dispatch_backend.rob_recover_active_w) &&
             (wait_i < 16)) begin
        if (!dut.u_dispatch_backend.rob_recover_active_w &&
            !post_recovery_checked) begin
          tb_check1("V8Y B ROB slot cleared after recovery",
                    dut.u_dispatch_backend.u_rob.valid_q[
                      branch_b_pid[ROB_INDEX_W-1:0]], 1'b0);
          tb_check1("V8Y B IQ holder cleared after recovery",
                    dut.u_dispatch_backend.int_iq_producer_live_mask_w[
                      branch_b_pid], 1'b0);
          tb_check1("V8Y B absent from global holder census",
                    dut.producer_live_mask_w[branch_b_pid], 1'b0);
          tb_check1("V8Y D remains exact-open after recovery",
                    dut.u_dispatch_backend.u_rob.valid_q[
                      survivor_pid[ROB_INDEX_W-1:0]], 1'b1);
          tb_check1("V8Y A remains exact-open after recovery",
                    dut.u_dispatch_backend.u_rob.valid_q[
                      branch_a_pid[ROB_INDEX_W-1:0]], 1'b1);
          post_recovery_checked = 1;
        end
        if (branch_resolve_valid)
          resolve_count = resolve_count + 1;
        if (dut.issue0_ctrlflow_fire_w &&
            (dut.iq_issue0_producer_id_w == branch_b_pid))
          branch_b_issue_count = branch_b_issue_count + 1;
        if ((dut.wb0_valid_w && (dut.wb0_producer_id_w == branch_b_pid)) ||
            (dut.wb1_valid_w && (dut.wb1_producer_id_w == branch_b_pid)))
          branch_b_complete_count = branch_b_complete_count + 1;
        if (dut.wb0_valid_w && (dut.wb0_producer_id_w == survivor_pid))
          survivor_complete_count = survivor_complete_count + 1;
        if (dut.wb1_valid_w && (dut.wb1_producer_id_w == survivor_pid))
          survivor_complete_count = survivor_complete_count + 1;
        if (dut.wb0_valid_w && (dut.wb0_producer_id_w == branch_a_pid))
          branch_a_complete_count = branch_a_complete_count + 1;
        if (dut.wb1_valid_w && (dut.wb1_producer_id_w == branch_a_pid))
          branch_a_complete_count = branch_a_complete_count + 1;
        if (commit0_valid) begin
          if (commit0_producer_id == survivor_pid)
            survivor_retire_count = survivor_retire_count + 1;
          else if (commit0_producer_id == branch_a_pid)
            branch_a_retire_count = branch_a_retire_count + 1;
          else if (commit0_producer_id == branch_b_pid)
            branch_b_retire_count = branch_b_retire_count + 1;
        end
        if (commit1_valid) begin
          if (dut.u_dispatch_backend.rob_commit1_producer_id_w == survivor_pid)
            survivor_retire_count = survivor_retire_count + 1;
          else if (dut.u_dispatch_backend.rob_commit1_producer_id_w ==
                   branch_a_pid)
            branch_a_retire_count = branch_a_retire_count + 1;
          else if (dut.u_dispatch_backend.rob_commit1_producer_id_w ==
                   branch_b_pid)
            branch_b_retire_count = branch_b_retire_count + 1;
        end
        `TB_TICK(clk);
        clear_dispatch();
        #1;
        wait_i = wait_i + 1;
      end

      tb_check32("V8Y survivor completion exactly once",
                 survivor_complete_count, 32'd1);
      tb_check32("V8Y branch A completion exactly once",
                 branch_a_complete_count, 32'd1);
      tb_check32("V8Y branch B never issues",
                 branch_b_issue_count, 32'd0);
      tb_check32("V8Y only branch A resolves",
                 resolve_count, 32'd1);
      tb_check32("V8Y branch B never completes",
                 branch_b_complete_count, 32'd0);
      tb_check32("V8Y survivor retires exactly once",
                 survivor_retire_count, 32'd1);
      tb_check32("V8Y branch A retires exactly once",
                 branch_a_retire_count, 32'd1);
      tb_check32("V8Y branch B never retires",
                 branch_b_retire_count, 32'd0);
      tb_check32("V8Y ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check1("V8Y empty ROB head and tail agree",
                dut.u_dispatch_backend.u_rob.head_q ==
                dut.u_dispatch_backend.u_rob.tail_q, 1'b1);
      tb_check32("V8Y IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("V8Y free list recovers", {25'b0, free_count}, 32'd32);
      tb_check1("V8Y ROB recovery drains",
                dut.u_dispatch_backend.rob_recover_active_w, 1'b0);
      tb_check1("V8Y resolve stage drains",
                dut.branch_resolve_stage_valid_w, 1'b0);
      tb_check1("V8Y EX stages drain", dut.ex0_valid_q || dut.ex1_valid_q,
                1'b0);
      tb_check1("V8Y producer holder census drains",
                |dut.producer_live_mask_w, 1'b0);
      tb_check32("V8Y memory owners remain empty",
                 dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8Y terminal collector remains empty",
                 dut.mem_terminal_pending_count_w, 32'd0);
      if (wrap_case)
        $display("[V8Y-CONTROL-RECOVERY] mode=wrap rob=D14,A15,B0 controls=2 oldest=A resolves=1 younger_issue=0 younger_resolve=0 complete_survivors=2 wrong_complete=0 retire_survivors=2 wrong_retire=0 ghosts=0 PASS");
      else
        $display("[V8Y-CONTROL-RECOVERY] mode=linear rob=D0,A1,B2 controls=2 oldest=A resolves=1 younger_issue=0 younger_resolve=0 complete_survivors=2 wrong_complete=0 retire_survivors=2 wrong_retire=0 ghosts=0 PASS");
      reset_dut();
    end
  endtask

  task automatic run_v8y_oldest_control_recovery;
    begin
      run_v8y_oldest_control_recovery_case(
          1'b0, 64'h0000_0000_8000_7300);
      run_v8y_oldest_control_recovery_case(
          1'b1, 64'h0000_0000_8000_7400);
      $display("[V8Y-CONTROL-RECOVERY-AGGREGATE] linear=1 wrap=1 full_pid_ledger=1 PASS");
    end
  endtask

  task automatic v8j_check_resolve_silent;
    input [1023:0] what;
    begin
      tb_check1(what,
                branch_resolve_valid || (|branch_resolve_pc) ||
                (|branch_resolve_next_pc) ||
                branch_resolve_misaligned ||
                (|branch_resolve_rob_idx) ||
                branch_resolve_mispredict ||
                branch_resolve_is_branch || branch_resolve_taken ||
                branch_resolve_pred_taken ||
                (|branch_resolve_bht_idx),
                1'b0);
    end
  endtask

  // Produce one real lane0 control-flow token and stop in the cycle where
  // branch_q and raw EX0_q are simultaneously visible.  The full PID is
  // copied to module-scope storage before any procedural force uses it.
  task automatic v8j_stage_branch;
    input [`XLEN-1:0] pc;
    input [`XLEN-1:0] predicted_next_pc;
    begin
      set_dispatch0(pc, make_branch_ctrl(`CMP_OP_EQ),
                    5'd0, 5'd0, 5'd0, 64'd8);
      dispatch0_pred_npc = predicted_next_pc;
      dispatch0_bht_idx = 10'h2d5;
      dispatch0_pred_taken = 1'b1;
      #1;
      tb_check1("v8j staged branch dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8j staged branch lane0 fire",
                dut.issue0_ctrlflow_fire_w, 1'b1);
      v8j_force_live_pid = dut.iq_issue0_producer_id_w;
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8j raw branch candidate present",
                dut.branch_resolve_candidate_valid_w, 1'b1);
      tb_check32("v8j branch q carries full issue PID",
                 {{(32-PRODUCER_ID_W){1'b0}},
                  dut.branch_resolve_payload_producer_id_w},
                 {{(32-PRODUCER_ID_W){1'b0}}, v8j_force_live_pid});
    end
  endtask

  task automatic run_v8j_branch_resolve_authorization;
    begin
      // Positive self-mispredict: resolve authority and EX completion share
      // the raw full-PID holder, emit exactly once, and current kill keeps the
      // boundary alive while starting strictly-younger recovery.
      reset_dut();
      v8j_stage_branch(64'h0000_0000_8000_7200,
                       64'h0000_0000_8000_7204);
      tb_check1("v8j live resolve query open",
                dut.branch_resolve_rob_open_w, 1'b1);
      tb_check1("v8j raw EX0 full-PID coherent",
                dut.branch_resolve_raw_ex0_coherent_w, 1'b1);
      tb_check1("v8j live capability authorized",
                dut.branch_resolve_authorized_w, 1'b1);
      tb_check1("v8j self-mispredict public pulse",
                branch_resolve_mispredict, 1'b1);
      tb_check1("v8j self-mispredict drives ROB kill",
                dut.u_dispatch_backend.rob_kill_valid_w, 1'b1);
      tb_check1("v8j branch boundary EX completion survives",
                dut.ex0_wb_valid_w, 1'b1);
      tb_check32("v8j raw boundary is authorized P.index",
                 {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
                 {{(32-ROB_INDEX_W){1'b0}},
                  v8j_force_live_pid[ROB_INDEX_W-1:0]});
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      v8j_check_resolve_silent("v8j self-mispredict emits exactly one cycle");

      // Coherence must read the raw registered token only.  An independently
      // closed completion/WB authority must not feed back and erase a valid
      // resolve capability; this makes semantic-valid substitutions observable.
      reset_dut();
      v8j_stage_branch(64'h0000_0000_8000_7210,
                       64'h0000_0000_8000_7218);
      force dut.ex0_producer_open_w = 1'b0;
      #1;
      tb_check1("v8j raw coherence ignores semantic completion open",
                dut.branch_resolve_raw_ex0_coherent_w, 1'b1);
      tb_check1("v8j raw-only capability survives semantic close",
                dut.branch_resolve_authorized_w, 1'b1);
      tb_check1("v8j raw-only public resolve survives semantic close",
                branch_resolve_valid, 1'b1);
      rst = 1'b1;
      #1;
      release dut.ex0_producer_open_w;
      `TB_TICK(clk);
      clear_dispatch();
      rst = 1'b0;
      #1;

      // Stale P and live Q share the same raw index.  Keep branch/raw-EX
      // coherence true so only ROB generation authority closes the effect.
      reset_dut();
      v8j_stage_branch(64'h0000_0000_8000_7220,
                       64'h0000_0000_8000_7228);
      v8j_force_stale_pid = v8j_force_live_pid;
      v8j_force_stale_pid[ROB_INDEX_W] =
          ~v8j_force_live_pid[ROB_INDEX_W];
      force dut.branch_resolve_payload_producer_id_w =
          v8j_force_stale_pid;
      force dut.ex0_producer_id_q = v8j_force_stale_pid;
      #1;
      tb_check1("v8j stale generation remains raw-EX coherent",
                dut.branch_resolve_raw_ex0_coherent_w, 1'b1);
      tb_check1("v8j stale generation closes ROB resolve query",
                dut.branch_resolve_rob_open_w, 1'b0);
      tb_check1("v8j stale generation denies capability",
                dut.branch_resolve_authorized_w, 1'b0);
      v8j_check_resolve_silent("v8j stale generation is fully silent");
      rst = 1'b1;
      #1;
      release dut.branch_resolve_payload_producer_id_w;
      release dut.ex0_producer_id_q;
      `TB_TICK(clk);
      clear_dispatch();
      rst = 1'b0;
      #1;

      // ROB P is live/open, but raw EX0 carries another generation.  Query
      // remains open while the production coherence fence fails closed.
      reset_dut();
      v8j_stage_branch(64'h0000_0000_8000_7240,
                       64'h0000_0000_8000_7248);
      v8j_force_mismatch_pid = v8j_force_live_pid;
      v8j_force_mismatch_pid[ROB_INDEX_W] =
          ~v8j_force_live_pid[ROB_INDEX_W];
      force dut.ex0_producer_id_q = v8j_force_mismatch_pid;
      #1;
      tb_check1("v8j live branch PID keeps ROB query open",
                dut.branch_resolve_rob_open_w, 1'b1);
      tb_check1("v8j raw EX0 generation mismatch detected",
                dut.branch_resolve_raw_ex0_coherent_w, 1'b0);
      tb_check1("v8j EX0 mismatch denies capability",
                dut.branch_resolve_authorized_w, 1'b0);
      v8j_check_resolve_silent("v8j EX0 mismatch is fully silent");
      rst = 1'b1;
      #1;
      release dut.ex0_producer_id_q;
      `TB_TICK(clk);
      clear_dispatch();
      rst = 1'b0;
      #1;

      // One staged live P exercises the caller's generic query-closed mask
      // plus recovery/cancel/reset death edges.  ROB-level tests separately
      // drive real done/invalid slot state because Icarus cannot force one
      // word of an unpacked variable array.
      reset_dut();
      v8j_stage_branch(64'h0000_0000_8000_7260,
                       64'h0000_0000_8000_7268);
      force dut.branch_resolve_rob_open_w = 1'b0;
      #1;
      v8j_check_resolve_silent("v8j generic query-closed candidate is fully silent");
      release dut.branch_resolve_rob_open_w;
      #1;
      tb_check1("v8j authority reopens after query-close probe",
                dut.branch_resolve_rob_open_w, 1'b1);
      flush = 1'b1;
      #1;
      v8j_check_resolve_silent("v8j flush masks every semantic output");
      flush = 1'b0;
      checkpoint_restore = 1'b1;
      #1;
      v8j_check_resolve_silent("v8j checkpoint masks every semantic output");
      checkpoint_restore = 1'b0;
      force dut.u_dispatch_backend.u_rob.recover_q = 1'b1;
      #1;
      tb_check1("v8j prior recovery closes query",
                dut.branch_resolve_rob_open_w, 1'b0);
      v8j_check_resolve_silent("v8j prior recovery is fully silent");
      rst = 1'b1;
      #1;
      release dut.u_dispatch_backend.u_rob.recover_q;
      v8j_check_resolve_silent("v8j reset masks every semantic output");
      `TB_TICK(clk);
      clear_dispatch();
      rst = 1'b0;
      #1;
      $display("[V8J-BRANCH-RESOLVE-AUTH] live/stale/mismatch/death-edge/self-kill PASS");
      reset_dut();
    end
  endtask

  task automatic run_v8k_pending_csr_lease_fence;
    reg [(1 << PRODUCER_ID_W)-1:0] expected_mask;
    begin
      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_0f40,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'd1);
      #1;
      tb_check1("v8k baseline candidate ready", dispatch0_ready, 1'b1);
      tb_check1("v8k public dispatch PID mirrors allocator",
                dispatch0_producer_id == dut.dispatch0_producer_id_w, 1'b1);
      v8k_candidate_pid = dispatch0_producer_id;

      // Model the registered raw lease presented by the pending-system owner.
      // It must enter the Q-only holder census as an exact onehot full PID and
      // fence reuse without depending on ready/fire/commit authorization.
      pending_system_producer_id = v8k_candidate_pid;
      pending_system_producer_valid = 1'b1;
      expected_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_mask[v8k_candidate_pid] = 1'b1;
      #1;
      tb_check1("v8k pending lease mask is exact onehot",
                dut.pending_system_producer_live_mask_w == expected_mask,
                1'b1);
      tb_check1("v8k pending lease reaches full holder census",
                dut.producer_live_mask_w[v8k_candidate_pid], 1'b1);
      tb_check1("v8k exact live PID blocks dispatch reuse",
                dispatch0_ready, 1'b0);
      tb_check1("v8k blocked candidate cannot fire",
                dut.dispatch0_fire_w, 1'b0);

      pending_system_producer_valid = 1'b0;
      #1;
      tb_check1("v8k lease death reopens candidate", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("v8k admitted candidate occupies one ROB entry",
                 {{(32-ROB_COUNT_W){1'b0}}, rob_count}, 32'd1);
      tb_check1("v8k public commit PID mirrors ROB head",
                commit0_producer_id == v8k_candidate_pid, 1'b1);
      $display("[V8K-PENDING-CSR-LEASE] raw onehot/reuse fence/public PID transport PASS");
      reset_dut();
    end
  endtask

  // v8l direct-holder census.  Forced probes are combinational and are
  // released before any clock edge; the final case uses the real
  // dispatch->IntIQ->EX0 path to prove the old Q holder covers the handoff
  // edge and the new Q holder covers the following cycle.
  task automatic run_v8l_transient_holder_census;
    reg [PRODUCER_ID_W-1:0] real_pid;
    reg [PRODUCER_ID_W-1:0] memory_pid;
    begin
      reset_dut();
      v8l_force_pid = {PRODUCER_ID_W{1'b0}};
      v8l_force_pid[PRODUCER_ID_W-1] = 1'b1;
      v8l_force_pid[ROB_INDEX_W-1:0] = 4'h6;

      force dut.mem_issue_res_valid_q = 1'b1;
      force dut.mem_issue_res_producer_id_q = v8l_force_pid;
      #1;
      tb_check1("v8l memory reservation direct mask",
                dut.mem_res_producer_live_mask_w[v8l_force_pid], 1'b1);
      tb_check1("v8l memory reservation reaches complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b1);
      release dut.mem_issue_res_valid_q;
      release dut.mem_issue_res_producer_id_q;
      reset_dut();
      tb_check1("v8l memory reservation release clears complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b0);

      v8l_force_pid[ROB_INDEX_W-1:0] = 4'h7;
      force dut.ex0_valid_q = 1'b1;
      force dut.ex0_producer_id_q = v8l_force_pid;
      #1;
      tb_check1("v8l EX0 direct mask",
                dut.ex0_producer_live_mask_w[v8l_force_pid], 1'b1);
      tb_check1("v8l EX0 reaches complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b1);
      release dut.ex0_valid_q;
      release dut.ex0_producer_id_q;
      reset_dut();
      tb_check1("v8l EX0 release clears complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b0);

      v8l_force_pid[ROB_INDEX_W-1:0] = 4'h8;
      force dut.ex1_valid_q = 1'b1;
      force dut.ex1_producer_id_q = v8l_force_pid;
      #1;
      tb_check1("v8l EX1 direct mask",
                dut.ex1_producer_live_mask_w[v8l_force_pid], 1'b1);
      tb_check1("v8l EX1 reaches complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b1);
      release dut.ex1_valid_q;
      release dut.ex1_producer_id_q;
      reset_dut();
      tb_check1("v8l EX1 release clears complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b0);

      v8l_force_pid[ROB_INDEX_W-1:0] = 4'h9;
      force dut.branch_resolve_stage_valid_w = 1'b1;
      force dut.branch_resolve_payload_producer_id_w = v8l_force_pid;
      #1;
      tb_check1("v8l branch packet direct mask",
                dut.branch_producer_live_mask_w[v8l_force_pid], 1'b1);
      tb_check1("v8l branch packet reaches complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b1);
      release dut.branch_resolve_stage_valid_w;
      release dut.branch_resolve_payload_producer_id_w;
      reset_dut();
      tb_check1("v8l branch packet release clears complete mask",
                dut.producer_live_mask_w[v8l_force_pid], 1'b0);

      reset_dut();
      commit_ready = 1'b0;
      set_dispatch0(32'h8000_0f80,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd10, 64'd3);
      #1;
      real_pid = dispatch0_producer_id;
      tb_check1("v8l real handoff dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8l real handoff starts in IntIQ",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[real_pid],
                1'b1);
      tb_check1("v8l IntIQ holder reaches complete mask",
                dut.producer_live_mask_w[real_pid], 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8l real handoff leaves IntIQ",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[real_pid],
                1'b0);
      tb_check1("v8l real handoff enters EX0 Q", dut.ex0_valid_q, 1'b1);
      tb_check1("v8l EX0 Q owns exact real P",
                dut.ex0_producer_id_q == real_pid, 1'b1);
      tb_check1("v8l EX0 handoff keeps complete lease",
                dut.producer_live_mask_w[real_pid], 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8l completed EX0 releases transient lease",
                dut.producer_live_mask_w[real_pid], 1'b0);

      // Drive a real memory uop to the issue head, then deny only the owner
      // tracker allocation credit.  The old IntIQ Q holder must remain live;
      // neither the reservation nor a token may be born until credit returns.
      // This force models tracker backpressure and is never applied to the
      // capture/ready gates being checked.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_0f90,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd11, 64'h8000_0590);
      #1;
      memory_pid = dispatch0_producer_id;
      tb_check1("v8l tracker-backpressure dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      force dut.mem_owner_alloc0_ready_w = 1'b0;
      #1;
      tb_check1("v8l tracker-backpressure presents memory candidate",
                dut.mem_issue_res_capture_candidate_w, 1'b1);
      tb_check1("v8l tracker-backpressure blocks capture",
                dut.mem_issue_res_capture_w, 1'b0);
      tb_check1("v8l tracker-backpressure blocks IQ pop",
                dut.iq_issue0_ready_w, 1'b0);
      tb_check1("v8l tracker-backpressure keeps old IntIQ lease",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid],
                1'b1);
      tb_check32("v8l tracker-backpressure creates no owner",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      `TB_TICK(clk);
      #1;
      tb_check1("v8l tracker-backpressure keeps IQ resident",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid],
                1'b1);
      tb_check1("v8l tracker-backpressure creates no reservation",
                dut.mem_issue_res_valid_q, 1'b0);
      release dut.mem_owner_alloc0_ready_w;
      #1;
      tb_check1("v8l tracker-credit return enables capture",
                dut.mem_issue_res_capture_w, 1'b1);
      tb_check1("v8l tracker-credit return enables IQ pop",
                dut.iq_issue0_ready_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8l tracker-credit handoff clears IntIQ holder",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[memory_pid],
                1'b0);
      tb_check1("v8l tracker-credit handoff creates reservation",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("v8l tracker-credit handoff creates token lease",
                dut.mem_owner_producer_live_mask_w[memory_pid], 1'b1);
      tb_check1("v8l tracker-credit handoff keeps complete lease",
                dut.producer_live_mask_w[memory_pid], 1'b1);
      $display("[V8L-TRACKER-BACKPRESSURE] old-IQ hold/no-capture then atomic reservation+token handoff PASS");
      $display("[V8L-TRANSIENT-HOLDER-CENSUS] mem-res/EX0/EX1/branch plus real IQ->EX0 handoff PASS");
      reset_dut();
    end
  endtask

  // v8m / OOO-2 selective scheduling.  A real memory uop establishes the
  // registered Universal owner under request backpressure.  The owner may
  // stop only issue0; ready ALU work must continue through physical issue1.
  task automatic run_v8m_selective_scheduling;
    reg [PRODUCER_ID_W-1:0] owner_pid;
    reg [PRODUCER_ID_W-1:0] older_alu_pid;
    reg [PRODUCER_ID_W-1:0] younger_alu_pid;
    reg [PRODUCER_ID_W-1:0] dependent_pid;
    reg [PRODUCER_ID_W-1:0] same_resource_pid;
    reg [PRODUCER_ID_W-1:0] target_pid;
    integer global_freeze_cycles;
    begin
      global_freeze_cycles = 0;

      // Counterexample A: two independent ALUs younger than the resident
      // memory owner.  The older ALU must be selected first; the reservation
      // cannot act as an arbitrary older-valid/global issue barrier.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_1000,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'h8000_0600);
      #1;
      owner_pid = dispatch0_producer_id;
      tb_check1("v8m owner seed dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8m owner seed capture candidate",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8m real Universal owner established",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("v8m real Universal owner identity",
                dut.mem_issue_res_producer_id_q == owner_pid, 1'b1);

      set_dispatch0(32'h8000_1010,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'd17);
      set_dispatch1(32'h8000_1014,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd7, 64'd19);
      #1;
      older_alu_pid = dispatch0_producer_id;
      younger_alu_pid = dut.dispatch1_producer_id_w;
      tb_check1("v8m independent pair dispatch0 ready",
                dispatch0_ready, 1'b1);
      tb_check1("v8m independent pair dispatch1 ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (dut.mem_issue_res_valid_q &&
          dut.u_dispatch_backend.u_issue_queue.issue1_found_w &&
          !flush && !checkpoint_restore && !dut.issue_block_w &&
          !dut.mem_rsp_waiting_for_wb_w && !dut.issue1_fire_w)
        global_freeze_cycles = global_freeze_cycles + 1;
      tb_check1("v8m owner suppresses Universal issue0",
                dut.iq_issue0_valid_w, 1'b0);
      tb_check1("v8m oldest independent ALU issue1 valid",
                dut.issue1_valid_w, 1'b1);
      tb_check1("v8m oldest independent ALU issue1 fire",
                dut.issue1_fire_w, 1'b1);
      tb_check32("v8m oldest independent ALU PC",
                 dut.issue1_pc_w[31:0], 32'h8000_1010);
      tb_check1("v8m oldest independent ALU full ProducerId",
                dut.issue1_producer_id_w == older_alu_pid, 1'b1);
      tb_check1("v8m observation has no ROB kill",
                dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
      tb_check1("v8m observation has no ROB recovery",
                dut.u_dispatch_backend.rob_recover_active_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("v8m older ALU left IQ exactly once",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[
                    older_alu_pid], 1'b0);
      tb_check1("v8m younger ALU remains after older fire",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[
                    younger_alu_pid], 1'b1);
      tb_check1("v8m older ALU enters EX1 with exact ProducerId",
                dut.ex1_valid_q &&
                (dut.ex1_producer_id_q == older_alu_pid), 1'b1);
      if (dut.mem_issue_res_valid_q &&
          dut.u_dispatch_backend.u_issue_queue.issue1_found_w &&
          !flush && !checkpoint_restore && !dut.issue_block_w &&
          !dut.mem_rsp_waiting_for_wb_w && !dut.issue1_fire_w)
        global_freeze_cycles = global_freeze_cycles + 1;
      tb_check1("v8m second independent ALU issue1 fire",
                dut.issue1_fire_w, 1'b1);
      tb_check1("v8m second independent ALU identity",
                (dut.issue1_pc_w[31:0] == 32'h8000_1014) &&
                (dut.issue1_producer_id_w == younger_alu_pid), 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("v8m independent ALUs drain from IQ",
                 {28'b0, issue_count}, 32'd0);
      tb_check1("v8m owner survives independent ALU progress",
                dut.mem_issue_res_valid_q, 1'b1);
      $display("[V8M-OLDER-INDEPENDENT] owner=%0d older=%0d younger=%0d terminal1 progress PASS",
               owner_pid, older_alu_pid, younger_alu_pid);

      // Counterexample B: an older dependent ALU and a same-resource memory
      // uop wait, while a younger independent ALU bypasses both via issue1.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      set_dispatch0(32'h8000_1020,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'h8000_0620);
      #1;
      owner_pid = dispatch0_producer_id;
      tb_check1("v8m selective owner dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8m selective owner capture candidate",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8m selective owner established",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("v8m selective owner exact ProducerId",
                dut.mem_issue_res_producer_id_q == owner_pid, 1'b1);

      set_dispatch0(32'h8000_1030,
                    make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
                    5'd5, 5'd0, 5'd6, 64'd1);
      set_dispatch1(32'h8000_1034,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h8000_0630);
      #1;
      dependent_pid = dispatch0_producer_id;
      same_resource_pid = dut.dispatch1_producer_id_w;
      tb_check1("v8m blocked pair dispatch0 ready",
                dispatch0_ready, 1'b1);
      tb_check1("v8m blocked pair dispatch1 ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("v8m dependent and memory remain resident",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("v8m dependent source is not ready",
                dut.u_dispatch_backend.u_issue_queue.src1_ready_q[0], 1'b0);
      tb_check1("v8m same-resource memory is classified",
                dut.u_dispatch_backend.u_issue_queue.select_memory_w[1],
                1'b1);
      tb_check1("v8m same-resource memory is ineligible",
                dut.u_dispatch_backend.u_issue_queue.select_eligible_w[1],
                1'b0);

      set_dispatch0(32'h8000_1038,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'd23);
      #1;
      target_pid = dispatch0_producer_id;
      tb_check1("v8m target independent dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      if (dut.mem_issue_res_valid_q &&
          dut.u_dispatch_backend.u_issue_queue.issue1_found_w &&
          !flush && !checkpoint_restore && !dut.issue_block_w &&
          !dut.mem_rsp_waiting_for_wb_w && !dut.issue1_fire_w)
        global_freeze_cycles = global_freeze_cycles + 1;
      tb_check1("v8m target window keeps real owner",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("v8m target window Universal remains exclusive",
                dut.iq_issue0_valid_w, 1'b0);
      tb_check1("v8m target window raw issue0 ready is local zero",
                dut.iq_issue0_ready_w, 1'b0);
      tb_check1("v8m target independent issue1 valid",
                dut.issue1_valid_w, 1'b1);
      tb_check1("v8m target independent issue1 ready",
                dut.issue1_ready_w, 1'b1);
      tb_check1("v8m target independent issue1 fire",
                dut.issue1_fire_w, 1'b1);
      tb_check32("v8m target independent exact PC",
                 dut.issue1_pc_w[31:0], 32'h8000_1038);
      tb_check1("v8m target independent exact ProducerId",
                dut.issue1_producer_id_w == target_pid, 1'b1);
      tb_check1("v8m target window has no flush", flush, 1'b0);
      tb_check1("v8m target window has no checkpoint restore",
                checkpoint_restore, 1'b0);
      tb_check1("v8m target window has no ROB kill",
                dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
      tb_check1("v8m target window has no ROB recovery",
                dut.u_dispatch_backend.rob_recover_active_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("v8m only target drains from three residents",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("v8m dependent remains blocked",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[
                    dependent_pid], 1'b1);
      tb_check1("v8m same-resource memory remains blocked",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[
                    same_resource_pid], 1'b1);
      tb_check1("v8m target leaves IQ exactly once",
                dut.u_dispatch_backend.int_iq_producer_live_mask_w[
                    target_pid], 1'b0);
      tb_check1("v8m target enters EX1 with exact ProducerId",
                dut.ex1_valid_q && (dut.ex1_producer_id_q == target_pid),
                1'b1);
      tb_check1("v8m reservation remains under memory backpressure",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check32("v8m no arbitrary global freeze cycles",
                 global_freeze_cycles, 32'd0);
      $display("[V8M-SELECTIVE-METRICS] blocked_dependents_only=1 younger_independent_issued=1 different_resource_issued=1 global_freeze_cycles=%0d target_pid=%0d",
               global_freeze_cycles, target_pid);
      $display("[V8M-SELECTIVE-SCHEDULING] real owner/dependent/same-resource/independent identity PASS");
      reset_dut();
    end
  endtask

  task automatic run_v8n_prime_producer_generation;
    integer pair_i;
    begin
      // Reset initializes each slot generation to all ones.  Consume one full
      // ROB turn so every v8n scored identity carries a non-zero generation;
      // a raw-index-only checker can no longer pass accidentally.
      for (pair_i = 0; pair_i < 8; pair_i = pair_i + 1) begin
        set_dispatch0(64'h0000_0000_8000_1100 + (pair_i * 8),
                      make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                      5'd0, 5'd0, 5'd30, 64'h40 + pair_i);
        set_dispatch1(64'h0000_0000_8000_1104 + (pair_i * 8),
                      make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                      5'd0, 5'd0, 5'd31, 64'h50 + pair_i);
        tick_dispatch_to_commit("v8n generation prime",
                                64'h40 + pair_i, 64'h50 + pair_i);
      end
      tb_check32("v8n generation prime ROB drains",
                 {27'b0, rob_count}, 32'd0);
      tb_check32("v8n generation prime free-list recovers",
                 {25'b0, free_count}, 32'd32);
    end
  endtask

  task automatic check_v8n_rob_nine_identity;
    input [1023:0] label;
    input [(1 << PRODUCER_ID_W)-1:0] younger_mask;
    input [PRODUCER_ID_W-1:0] old_pid;
    reg [(1 << PRODUCER_ID_W)-1:0] actual_mask;
    reg [(1 << PRODUCER_ID_W)-1:0] expected_mask;
    reg [PRODUCER_ID_W-1:0] slot_pid;
    integer slot;
    integer actual_count;
    begin
      actual_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_mask = younger_mask;
      expected_mask[old_pid] = 1'b1;
      actual_count = 0;
      for (slot = 0; slot < (1 << ROB_INDEX_W); slot = slot + 1) begin
        if (dut.u_dispatch_backend.u_rob.valid_q[slot]) begin
          slot_pid[ROB_INDEX_W-1:0] = slot;
          slot_pid[PRODUCER_ID_W-1:ROB_INDEX_W] =
              dut.u_dispatch_backend.u_rob.slot_generation_q[slot];
          tb_check1({label, " ROB PID unique"},
                    actual_mask[slot_pid], 1'b0);
          actual_mask[slot_pid] = 1'b1;
          actual_count = actual_count + 1;
        end
      end
      tb_check32({label, " has nine real valid ROB entries"},
                 actual_count, 32'd9);
      tb_check1({label, " ROB full-PID set matches dispatch ledger"},
                actual_mask == expected_mask, 1'b1);
      if (actual_count > v8n_rob_valid_peak)
        v8n_rob_valid_peak = actual_count;
    end
  endtask

  // v8n / OOO-1 load-miss proof.  The request is accepted into the real
  // MIQ/tracker and its response is withheld until eight distinct younger
  // ALUs have reached formal EX completion.  Full ProducerId, rather than a
  // raw ROB index, binds every completion and retirement observation.
  task automatic run_v8n_load_miss_eight_younger;
    localparam [`XLEN-1:0] OLD_PC = 64'h0000_0000_8000_1200;
    localparam [`XLEN-1:0] YOUNGER_PC = 64'h0000_0000_8000_1220;
    reg [PRODUCER_ID_W-1:0] old_pid;
    reg [(1 << PRODUCER_ID_W)-1:0] younger_expected_mask;
    reg [(1 << PRODUCER_ID_W)-1:0] younger_done_mask;
    reg [(9*PRODUCER_ID_W)-1:0] expected_pid_seq;
    reg [(9*32)-1:0] expected_pc_seq;
    reg [PRODUCER_ID_W-1:0] observed_pid;
    reg [PRODUCER_ID_W-1:0] expected_pid;
    reg [31:0] expected_pc;
    integer younger_i;
    integer younger_done_count;
    integer old_wb_count;
    integer commit_seen;
    integer cycles;
    integer pid_value;
    integer younger_issue_count;
    integer dual_issue_cycles;
    reg [(1 << PRODUCER_ID_W)-1:0] younger_issue_mask;
    begin
      reset_dut();
      run_v8n_prime_producer_generation();
      v8n_load_miss_completed = 0;
      younger_expected_mask = {(1 << PRODUCER_ID_W){1'b0}};
      younger_done_mask = {(1 << PRODUCER_ID_W){1'b0}};
      younger_issue_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_pid_seq = {(9*PRODUCER_ID_W){1'b0}};
      expected_pc_seq = {(9*32){1'b0}};
      younger_done_count = 0;
      old_wb_count = 0;
      commit_seen = 0;
      cycles = 0;
      younger_issue_count = 0;
      dual_issue_cycles = 0;

      set_dispatch0(OLD_PC, make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h0000_0000_8000_0700);
      #1;
      old_pid = dispatch0_producer_id;
      expected_pid_seq[0 +: PRODUCER_ID_W] = old_pid;
      expected_pc_seq[0 +: 32] = OLD_PC[31:0];
      tb_check1("v8n load old dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("v8n load enters real reservation capture",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("v8n load reservation valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("v8n load reservation exact ProducerId",
                dut.mem_issue_res_producer_id_q == old_pid, 1'b1);
      tb_check1("v8n load request visible", mem_req_valid, 1'b1);
      tb_check1("v8n load request accepted", mem_req_ready, 1'b1);
      tb_check1("v8n load request is read", mem_req_write, 1'b0);
      tb_check64("v8n load request address", mem_req_addr,
                 64'h0000_0000_8000_0700);
      `TB_TICK(clk);
      #1;
      tb_check1("v8n load owner reaches MIQ", dut.miq_head_valid_w, 1'b1);
      tb_check1("v8n load MIQ kind", dut.miq_head_load_w, 1'b1);
      tb_check1("v8n load tracker tuple visible", mem_expected_valid, 1'b1);
      tb_check1("v8n load completion identity prepared",
                dut.mem_completion_producer_id_w == old_pid, 1'b1);
      tb_check1("v8n load old PID has nonzero generation",
                |old_pid[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);

      younger_i = 0;
      while (((younger_i < 8) || (younger_done_count < 8)) &&
             (cycles < 48)) begin
        if (younger_i < 8) begin
          set_dispatch0(YOUNGER_PC + (younger_i * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd10 + younger_i,
                        64'h200 + younger_i);
          set_dispatch1(YOUNGER_PC + ((younger_i + 1) * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd11 + younger_i,
                        64'h201 + younger_i);
          #1;
          tb_check1("v8n load younger dispatch0 ready",
                    dispatch0_ready, 1'b1);
          tb_check1("v8n load younger dispatch1 ready",
                    dispatch1_ready, 1'b1);
          observed_pid = dispatch0_producer_id;
          pid_value = observed_pid;
          tb_check1("v8n load younger0 differs from old PID",
                    observed_pid != old_pid, 1'b1);
          tb_check1("v8n load younger0 has nonzero generation",
                    |observed_pid[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
          tb_check1("v8n load younger0 PID unique",
                    younger_expected_mask[pid_value], 1'b0);
          younger_expected_mask[pid_value] = 1'b1;
          expected_pid_seq[(younger_i + 1)*PRODUCER_ID_W +:
                           PRODUCER_ID_W] = observed_pid;
          expected_pc_seq[(younger_i + 1)*32 +: 32] =
              YOUNGER_PC[31:0] + (younger_i * 4);

          observed_pid = dut.dispatch1_producer_id_w;
          pid_value = observed_pid;
          tb_check1("v8n load younger1 differs from old PID",
                    observed_pid != old_pid, 1'b1);
          tb_check1("v8n load younger1 has nonzero generation",
                    |observed_pid[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
          tb_check1("v8n load younger1 PID unique",
                    younger_expected_mask[pid_value], 1'b0);
          younger_expected_mask[pid_value] = 1'b1;
          expected_pid_seq[(younger_i + 2)*PRODUCER_ID_W +:
                           PRODUCER_ID_W] = observed_pid;
          expected_pc_seq[(younger_i + 2)*32 +: 32] =
              YOUNGER_PC[31:0] + ((younger_i + 1) * 4);
        end

        if (dut.issue0_fire_w) begin
          observed_pid = dut.iq_issue0_producer_id_w;
          pid_value = observed_pid;
          tb_check1("v8n load issue0 accept belongs to younger set",
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1("v8n load issue0 accept exactly once",
                    younger_issue_mask[pid_value], 1'b0);
          tb_check1("v8n load issue0 occurs with exact live owner",
                    dut.miq_head_valid_w && mem_expected_valid &&
                    (dut.mem_completion_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_issue_mask[pid_value]) begin
            younger_issue_mask[pid_value] = 1'b1;
            younger_issue_count = younger_issue_count + 1;
          end
        end
        if (dut.issue1_fire_w) begin
          observed_pid = dut.issue1_producer_id_w;
          pid_value = observed_pid;
          tb_check1("v8n load issue1 accept belongs to younger set",
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1("v8n load issue1 accept exactly once",
                    younger_issue_mask[pid_value], 1'b0);
          tb_check1("v8n load issue1 occurs with exact live owner",
                    dut.miq_head_valid_w && mem_expected_valid &&
                    (dut.mem_completion_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_issue_mask[pid_value]) begin
            younger_issue_mask[pid_value] = 1'b1;
            younger_issue_count = younger_issue_count + 1;
          end
        end
        if (dut.issue0_fire_w && dut.issue1_fire_w) begin
          dual_issue_cycles = dual_issue_cycles + 1;
          tb_check1("v8n load dual issue accepts different PIDs",
                    dut.iq_issue0_producer_id_w !=
                    dut.issue1_producer_id_w, 1'b1);
        end

        if (dut.ex0_wb_valid_w) begin
          observed_pid = dut.ex0_producer_id_q;
          pid_value = observed_pid;
          tb_check1("v8n load EX0 completion belongs to younger set",
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1("v8n load EX0 completion exactly once",
                    younger_done_mask[pid_value], 1'b0);
          tb_check1("v8n load EX0 completion is authorized",
                    dut.ex0_producer_open_w && !dut.ex0_kill_now_w, 1'b1);
          tb_check1("v8n load EX0 completes under exact live owner",
                    dut.miq_head_valid_w && mem_expected_valid &&
                    (dut.mem_completion_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_done_mask[pid_value]) begin
            younger_done_mask[pid_value] = 1'b1;
            younger_done_count = younger_done_count + 1;
          end
        end
        if (dut.ex1_wb_valid_w) begin
          observed_pid = dut.ex1_producer_id_q;
          pid_value = observed_pid;
          tb_check1("v8n load EX1 completion belongs to younger set",
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1("v8n load EX1 completion exactly once",
                    younger_done_mask[pid_value], 1'b0);
          tb_check1("v8n load EX1 completion is authorized",
                    dut.ex1_producer_open_w && !dut.ex1_kill_now_w, 1'b1);
          tb_check1("v8n load EX1 completes under exact live owner",
                    dut.miq_head_valid_w && mem_expected_valid &&
                    (dut.mem_completion_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_done_mask[pid_value]) begin
            younger_done_mask[pid_value] = 1'b1;
            younger_done_count = younger_done_count + 1;
          end
        end

        if (commit0_valid || commit1_valid) begin
          v8n_retire_order_violations =
              v8n_retire_order_violations + 1;
          tb_check1("v8n load no retirement before old completion",
                    commit0_valid || commit1_valid, 1'b0);
        end
        tb_check1("v8n load window retains MIQ owner",
                  dut.miq_head_valid_w, 1'b1);
        tb_check1("v8n load window has no flush", flush, 1'b0);
        tb_check1("v8n load window has no checkpoint restore",
                  checkpoint_restore, 1'b0);
        tb_check1("v8n load window has no ROB kill",
                  dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
        tb_check1("v8n load window has no ROB recovery",
                  dut.u_dispatch_backend.rob_recover_active_w, 1'b0);
        tb_check1("v8n load window global issue gate open",
                  dut.issue_block_w, 1'b0);

        if (rob_count > v8n_rob_peak)
          v8n_rob_peak = rob_count;
        `TB_TICK(clk);
        clear_dispatch();
        if (younger_i < 8)
          younger_i = younger_i + 2;
        #1;
        if (rob_count > v8n_rob_peak)
          v8n_rob_peak = rob_count;
        cycles = cycles + 1;
      end

      tb_check32("v8n load all younger PIDs complete",
                 younger_done_count, 32'd8);
      tb_check32("v8n load all younger PIDs issue-accepted",
                 younger_issue_count, 32'd8);
      tb_check32("v8n load four dual-issue accept cycles",
                 dual_issue_cycles, 32'd4);
      tb_check1("v8n load issue PID masks agree",
                younger_issue_mask == younger_expected_mask, 1'b1);
      tb_check1("v8n load younger PID masks agree",
                younger_done_mask == younger_expected_mask, 1'b1);
      tb_check32("v8n load ROB holds old plus eight",
                 {27'b0, rob_count}, 32'd9);
      tb_check1("v8n load remains outstanding before response",
                dut.miq_head_valid_w, 1'b1);
      check_v8n_rob_nine_identity("v8n load peak",
                                  younger_expected_mask, old_pid);
      $display("[V8N-ACTIVATION] scenario=load_miss owner_pid=%0d owner_live=%0d issue_accept=%0d dual_issue=%0d younger_wb=%0d",
               old_pid, dut.miq_head_valid_w && mem_expected_valid,
               younger_issue_count, dual_issue_cycles,
               younger_done_count);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0123_4567_89ab_cdef;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("v8n load response ready", mem_rsp_ready, 1'b1);
      tb_check1("v8n load formal completion fires",
                dut.mem_wb0_valid_w || dut.mem_wb1_valid_w, 1'b1);
      tb_check1("v8n load formal completion exact ProducerId",
                dut.mem_completion_producer_id_w == old_pid, 1'b1);
      tb_check1("v8n load formal WB has no same-cycle retire",
                commit0_valid || commit1_valid, 1'b0);
      old_wb_count = old_wb_count + 1;
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      cycles = 0;
      while ((commit_seen < 9) && (cycles < 32)) begin
        if (commit0_valid) begin
          if (commit_seen >= 9) begin
            v8n_retire_order_violations =
                v8n_retire_order_violations + 1;
          end else begin
            expected_pid = expected_pid_seq[
                commit_seen*PRODUCER_ID_W +: PRODUCER_ID_W];
            expected_pc = expected_pc_seq[commit_seen*32 +: 32];
            if ((commit0_producer_id != expected_pid) ||
                (commit0_pc[31:0] != expected_pc))
              v8n_retire_order_violations =
                  v8n_retire_order_violations + 1;
            tb_check1("v8n load commit0 exact PID and PC",
                      (commit0_producer_id == expected_pid) &&
                      (commit0_pc[31:0] == expected_pc), 1'b1);
            if (commit_seen == 0)
              tb_check64("v8n load old commit data", commit0_data,
                         64'h0123_4567_89ab_cdef);
          end
          commit_seen = commit_seen + 1;
        end
        if (commit1_valid) begin
          if (commit_seen >= 9) begin
            v8n_retire_order_violations =
                v8n_retire_order_violations + 1;
          end else begin
            expected_pid = expected_pid_seq[
                commit_seen*PRODUCER_ID_W +: PRODUCER_ID_W];
            expected_pc = expected_pc_seq[commit_seen*32 +: 32];
            if ((dut.u_dispatch_backend.rob_commit1_producer_id_w !=
                 expected_pid) || (commit1_pc[31:0] != expected_pc))
              v8n_retire_order_violations =
                  v8n_retire_order_violations + 1;
            tb_check1("v8n load commit1 exact PID and PC",
                      (dut.u_dispatch_backend.rob_commit1_producer_id_w ==
                       expected_pid) &&
                      (commit1_pc[31:0] == expected_pc), 1'b1);
            if (commit_seen == 0)
              tb_check64("v8n load old commit1 data", commit1_data,
                         64'h0123_4567_89ab_cdef);
          end
          commit_seen = commit_seen + 1;
        end
        `TB_TICK(clk);
        #1;
        cycles = cycles + 1;
      end

      v8n_load_miss_completed = younger_done_count;
      v8n_load_issue_accepted = younger_issue_count;
      v8n_load_dual_issue_cycles = dual_issue_cycles;
      v8n_load_owner_live_completions = younger_done_count;
      tb_check32("v8n load old WB exactly once", old_wb_count, 32'd1);
      tb_check32("v8n load ordered commit count", commit_seen, 32'd9);
      tb_check32("v8n load ROB drains", {27'b0, rob_count}, 32'd0);
      tb_check32("v8n load IQ drains", {28'b0, issue_count}, 32'd0);
      tb_check32("v8n load free-list recovers",
                 {25'b0, free_count}, 32'd32);
      tb_check32("v8n load MIQ drains",
                 {28'b0, dut.miq_count_w}, 32'd0);
      tb_check32("v8n load tracker drains",
                 {26'b0, dut.mem_owner_live_count_w}, 32'd0);
      tb_check1("v8n load reservation drains",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("v8n load legacy holder drains", dut.mem_pending_q, 1'b0);
      $display("[V8N-LOAD-MISS-8-YOUNGER] completed=%0d commits=%0d old_pid=%0d PASS",
               younger_done_count, commit_seen, old_pid);
      reset_dut();
    end
  endtask

  // Shared production-path proof for iterative MUL and DIVU.  The operands
  // intentionally avoid fast terminals, and the old MulDiv full ProducerId
  // remains live while eight younger ALUs complete through EX0/EX1.
  task automatic run_v8n_muldiv_eight_younger;
    input [1023:0] label;
    input [2:0] funct3;
    input [`XLEN-1:0] lhs;
    input [`XLEN-1:0] rhs;
    input [`XLEN-1:0] expected_result;
    input [`XLEN-1:0] old_pc;
    input [`XLEN-1:0] younger_pc;
    input is_div;
    reg [PRODUCER_ID_W-1:0] old_pid;
    reg [(1 << PRODUCER_ID_W)-1:0] younger_expected_mask;
    reg [(1 << PRODUCER_ID_W)-1:0] younger_done_mask;
    reg [(9*PRODUCER_ID_W)-1:0] expected_pid_seq;
    reg [(9*32)-1:0] expected_pc_seq;
    reg [PRODUCER_ID_W-1:0] observed_pid;
    reg [PRODUCER_ID_W-1:0] expected_pid;
    reg [31:0] expected_pc;
    integer younger_i;
    integer younger_done_count;
    integer old_wb_count;
    integer commit_seen;
    integer cycles;
    integer pid_value;
    integer younger_issue_count;
    integer dual_issue_cycles;
    integer activation_reported;
    reg [(1 << PRODUCER_ID_W)-1:0] younger_issue_mask;
    begin
      reset_dut();
      run_v8n_prime_producer_generation();
      younger_expected_mask = {(1 << PRODUCER_ID_W){1'b0}};
      younger_done_mask = {(1 << PRODUCER_ID_W){1'b0}};
      younger_issue_mask = {(1 << PRODUCER_ID_W){1'b0}};
      expected_pid_seq = {(9*PRODUCER_ID_W){1'b0}};
      expected_pc_seq = {(9*32){1'b0}};
      younger_done_count = 0;
      old_wb_count = 0;
      commit_seen = 0;
      cycles = 0;
      younger_issue_count = 0;
      dual_issue_cycles = 0;
      activation_reported = 0;

      set_dispatch0(old_pc - 64'h20,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, lhs);
      set_dispatch1(old_pc - 64'h1c,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, rhs);
      tick_dispatch_to_commit({label, " operand setup"}, lhs, rhs);

      set_dispatch0(old_pc, make_muldiv_ctrl(),
                    5'd1, 5'd2, 5'd9, 64'd0);
      dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd2, 5'd1,
                               funct3, 5'd9);
      #1;
      old_pid = dispatch0_producer_id;
      expected_pid_seq[0 +: PRODUCER_ID_W] = old_pid;
      expected_pc_seq[0 +: 32] = old_pc[31:0];
      tb_check1({label, " old dispatch ready"}, dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1({label, " old selected on Universal terminal"},
                dut.issue0_valid_w, 1'b1);
      tb_check1({label, " old issue exact ProducerId"},
                dut.iq_issue0_producer_id_w == old_pid, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1({label, " request buffered"},
                dut.u_muldiv_unit.state_q == 3'd1, 1'b1);
      tb_check1({label, " buffered owner exact ProducerId"},
                dut.muldiv_owner_producer_id_w == old_pid, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1({label, " iterative state entered"},
                dut.u_muldiv_unit.state_q == (is_div ? 3'd3 : 3'd2),
                1'b1);
      tb_check1({label, " iterative owner remains live"},
                dut.muldiv_owner_valid_w, 1'b1);
      tb_check1({label, " old PID has nonzero generation"},
                |old_pid[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);

      younger_i = 0;
      while (((commit_seen < 9) || (old_wb_count < 1)) &&
             (cycles < 96)) begin
        if (younger_i < 8) begin
          set_dispatch0(younger_pc + (younger_i * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd10 + younger_i,
                        64'h300 + younger_i);
          set_dispatch1(younger_pc + ((younger_i + 1) * 4),
                        make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                      `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                        5'd0, 5'd0, 5'd11 + younger_i,
                        64'h301 + younger_i);
          #1;
          tb_check1({label, " younger dispatch0 ready"},
                    dispatch0_ready, 1'b1);
          tb_check1({label, " younger dispatch1 ready"},
                    dispatch1_ready, 1'b1);
          observed_pid = dispatch0_producer_id;
          pid_value = observed_pid;
          tb_check1({label, " younger0 differs from old PID"},
                    observed_pid != old_pid, 1'b1);
          tb_check1({label, " younger0 has nonzero generation"},
                    |observed_pid[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
          tb_check1({label, " younger0 PID unique"},
                    younger_expected_mask[pid_value], 1'b0);
          younger_expected_mask[pid_value] = 1'b1;
          expected_pid_seq[(younger_i + 1)*PRODUCER_ID_W +:
                           PRODUCER_ID_W] = observed_pid;
          expected_pc_seq[(younger_i + 1)*32 +: 32] =
              younger_pc[31:0] + (younger_i * 4);

          observed_pid = dut.dispatch1_producer_id_w;
          pid_value = observed_pid;
          tb_check1({label, " younger1 differs from old PID"},
                    observed_pid != old_pid, 1'b1);
          tb_check1({label, " younger1 has nonzero generation"},
                    |observed_pid[PRODUCER_ID_W-1:ROB_INDEX_W], 1'b1);
          tb_check1({label, " younger1 PID unique"},
                    younger_expected_mask[pid_value], 1'b0);
          younger_expected_mask[pid_value] = 1'b1;
          expected_pid_seq[(younger_i + 2)*PRODUCER_ID_W +:
                           PRODUCER_ID_W] = observed_pid;
          expected_pc_seq[(younger_i + 2)*32 +: 32] =
              younger_pc[31:0] + ((younger_i + 1) * 4);
        end

        if (dut.issue0_fire_w) begin
          observed_pid = dut.iq_issue0_producer_id_w;
          pid_value = observed_pid;
          tb_check1({label, " issue0 accept belongs to younger set"},
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1({label, " issue0 accept exactly once"},
                    younger_issue_mask[pid_value], 1'b0);
          tb_check1({label, " issue0 occurs under exact live owner"},
                    dut.muldiv_owner_valid_w &&
                    (dut.muldiv_owner_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_issue_mask[pid_value]) begin
            younger_issue_mask[pid_value] = 1'b1;
            younger_issue_count = younger_issue_count + 1;
          end
        end
        if (dut.issue1_fire_w) begin
          observed_pid = dut.issue1_producer_id_w;
          pid_value = observed_pid;
          tb_check1({label, " issue1 accept belongs to younger set"},
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1({label, " issue1 accept exactly once"},
                    younger_issue_mask[pid_value], 1'b0);
          tb_check1({label, " issue1 occurs under exact live owner"},
                    dut.muldiv_owner_valid_w &&
                    (dut.muldiv_owner_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_issue_mask[pid_value]) begin
            younger_issue_mask[pid_value] = 1'b1;
            younger_issue_count = younger_issue_count + 1;
          end
        end
        if (dut.issue0_fire_w && dut.issue1_fire_w) begin
          dual_issue_cycles = dual_issue_cycles + 1;
          tb_check1({label, " dual issue accepts different PIDs"},
                    dut.iq_issue0_producer_id_w !=
                    dut.issue1_producer_id_w, 1'b1);
        end

        if (dut.ex0_wb_valid_w) begin
          observed_pid = dut.ex0_producer_id_q;
          pid_value = observed_pid;
          tb_check1({label, " EX0 completion belongs to younger set"},
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1({label, " EX0 completion exactly once"},
                    younger_done_mask[pid_value], 1'b0);
          tb_check1({label, " EX0 completion is authorized"},
                    dut.ex0_producer_open_w && !dut.ex0_kill_now_w, 1'b1);
          tb_check1({label, " EX0 completes under exact live owner"},
                    dut.muldiv_owner_valid_w &&
                    (dut.muldiv_owner_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_done_mask[pid_value]) begin
            younger_done_mask[pid_value] = 1'b1;
            younger_done_count = younger_done_count + 1;
          end
        end
        if (dut.ex1_wb_valid_w) begin
          observed_pid = dut.ex1_producer_id_q;
          pid_value = observed_pid;
          tb_check1({label, " EX1 completion belongs to younger set"},
                    younger_expected_mask[pid_value], 1'b1);
          tb_check1({label, " EX1 completion exactly once"},
                    younger_done_mask[pid_value], 1'b0);
          tb_check1({label, " EX1 completion is authorized"},
                    dut.ex1_producer_open_w && !dut.ex1_kill_now_w, 1'b1);
          tb_check1({label, " EX1 completes under exact live owner"},
                    dut.muldiv_owner_valid_w &&
                    (dut.muldiv_owner_producer_id_w == old_pid), 1'b1);
          if (younger_expected_mask[pid_value] &&
              !younger_done_mask[pid_value]) begin
            younger_done_mask[pid_value] = 1'b1;
            younger_done_count = younger_done_count + 1;
          end
        end

        if (!activation_reported && (younger_issue_count == 8) &&
            (younger_done_count == 8) &&
            dut.muldiv_owner_valid_w) begin
          $display("[V8N-ACTIVATION] scenario=%0s owner_pid=%0d owner_live=1 issue_accept=%0d dual_issue=%0d younger_wb=%0d",
                   label, old_pid, younger_issue_count,
                   dual_issue_cycles, younger_done_count);
          activation_reported = 1;
        end

        if (dut.muldiv_wb0_valid_w || dut.muldiv_wb1_valid_w) begin
          old_wb_count = old_wb_count + 1;
          tb_check1({label, " old completion exact ProducerId"},
                    dut.muldiv_resp_producer_id_w == old_pid, 1'b1);
          tb_check64({label, " old completion data"},
                     dut.muldiv_resp_data_w, expected_result);
          tb_check32({label, " all younger complete before old"},
                     younger_done_count, 32'd8);
          tb_check1({label, " formal WB has no same-cycle retire"},
                    commit0_valid || commit1_valid, 1'b0);
        end

        if ((old_wb_count == 0) && (commit0_valid || commit1_valid)) begin
          v8n_retire_order_violations =
              v8n_retire_order_violations + 1;
          tb_check1({label, " no retirement before old completion"},
                    commit0_valid || commit1_valid, 1'b0);
        end

        if (commit0_valid) begin
          if (commit_seen >= 9) begin
            v8n_retire_order_violations =
                v8n_retire_order_violations + 1;
          end else begin
            expected_pid = expected_pid_seq[
                commit_seen*PRODUCER_ID_W +: PRODUCER_ID_W];
            expected_pc = expected_pc_seq[commit_seen*32 +: 32];
            if ((commit0_producer_id != expected_pid) ||
                (commit0_pc[31:0] != expected_pc))
              v8n_retire_order_violations =
                  v8n_retire_order_violations + 1;
            tb_check1({label, " commit0 exact PID and PC"},
                      (commit0_producer_id == expected_pid) &&
                      (commit0_pc[31:0] == expected_pc), 1'b1);
            if (commit_seen == 0)
              tb_check64({label, " old commit data"},
                         commit0_data, expected_result);
          end
          commit_seen = commit_seen + 1;
        end
        if (commit1_valid) begin
          if (commit_seen >= 9) begin
            v8n_retire_order_violations =
                v8n_retire_order_violations + 1;
          end else begin
            expected_pid = expected_pid_seq[
                commit_seen*PRODUCER_ID_W +: PRODUCER_ID_W];
            expected_pc = expected_pc_seq[commit_seen*32 +: 32];
            if ((dut.u_dispatch_backend.rob_commit1_producer_id_w !=
                 expected_pid) || (commit1_pc[31:0] != expected_pc))
              v8n_retire_order_violations =
                  v8n_retire_order_violations + 1;
            tb_check1({label, " commit1 exact PID and PC"},
                      (dut.u_dispatch_backend.rob_commit1_producer_id_w ==
                       expected_pid) &&
                      (commit1_pc[31:0] == expected_pc), 1'b1);
            if (commit_seen == 0)
              tb_check64({label, " old commit1 data"},
                         commit1_data, expected_result);
          end
          commit_seen = commit_seen + 1;
        end

        if ((old_wb_count == 0) && dut.muldiv_owner_valid_w) begin
          tb_check1({label, " window has no flush"}, flush, 1'b0);
          tb_check1({label, " window has no checkpoint restore"},
                    checkpoint_restore, 1'b0);
          tb_check1({label, " window has no ROB kill"},
                    dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
          tb_check1({label, " window has no ROB recovery"},
                    dut.u_dispatch_backend.rob_recover_active_w, 1'b0);
          tb_check1({label, " window global issue gate open"},
                    dut.issue_block_w, 1'b0);
          tb_check1({label, " owner identity remains exact"},
                    dut.muldiv_owner_producer_id_w == old_pid, 1'b1);
        end

        if (rob_count > v8n_rob_peak)
          v8n_rob_peak = rob_count;
        `TB_TICK(clk);
        clear_dispatch();
        if (younger_i < 8)
          younger_i = younger_i + 2;
        #1;
        if (rob_count > v8n_rob_peak)
          v8n_rob_peak = rob_count;
        cycles = cycles + 1;
        if ((younger_i == 8) && (cycles == 4)) begin
          tb_check32({label, " ROB holds old plus eight"},
                     {27'b0, rob_count}, 32'd9);
          check_v8n_rob_nine_identity({label, " peak"},
                                      younger_expected_mask, old_pid);
        end
      end

      if (is_div) begin
        v8n_div_completed = younger_done_count;
        v8n_div_issue_accepted = younger_issue_count;
        v8n_div_dual_issue_cycles = dual_issue_cycles;
        v8n_div_owner_live_completions = younger_done_count;
      end else begin
        v8n_mul_completed = younger_done_count;
        v8n_mul_issue_accepted = younger_issue_count;
        v8n_mul_dual_issue_cycles = dual_issue_cycles;
        v8n_mul_owner_live_completions = younger_done_count;
      end
      tb_check32({label, " younger completion count"},
                 younger_done_count, 32'd8);
      tb_check32({label, " younger issue-accept count"},
                 younger_issue_count, 32'd8);
      tb_check32({label, " four dual-issue accept cycles"},
                 dual_issue_cycles, 32'd4);
      tb_check1({label, " younger issue PID masks agree"},
                younger_issue_mask == younger_expected_mask, 1'b1);
      tb_check1({label, " younger PID masks agree"},
                younger_done_mask == younger_expected_mask, 1'b1);
      tb_check32({label, " old WB exactly once"}, old_wb_count, 32'd1);
      tb_check32({label, " ordered commit count"}, commit_seen, 32'd9);
      tb_check32({label, " ROB drains"}, {27'b0, rob_count}, 32'd0);
      tb_check32({label, " IQ drains"}, {28'b0, issue_count}, 32'd0);
      tb_check32({label, " free-list recovers"},
                 {25'b0, free_count}, 32'd32);
      tb_check1({label, " MulDiv owner drains"},
                dut.muldiv_owner_valid_w, 1'b0);
      $display("[V8N-MULDIV-8-YOUNGER] kind=%0s completed=%0d commits=%0d old_pid=%0d PASS",
               label, younger_done_count, commit_seen, old_pid);
      reset_dut();
    end
  endtask

  task automatic run_v8n_true_ooo_long_latency;
    begin
      v8n_load_miss_completed = 0;
      v8n_mul_completed = 0;
      v8n_div_completed = 0;
      v8n_load_issue_accepted = 0;
      v8n_mul_issue_accepted = 0;
      v8n_div_issue_accepted = 0;
      v8n_load_dual_issue_cycles = 0;
      v8n_mul_dual_issue_cycles = 0;
      v8n_div_dual_issue_cycles = 0;
      v8n_load_owner_live_completions = 0;
      v8n_mul_owner_live_completions = 0;
      v8n_div_owner_live_completions = 0;
      v8n_rob_valid_peak = 0;
      v8n_rob_peak = 0;
      v8n_retire_order_violations = 0;
      run_v8n_load_miss_eight_younger();
      run_v8n_muldiv_eight_younger(
          "v8n MUL", 3'b000,
          64'h1234_5678_9abc_def0, 64'h0fed_cba9_8765_4321,
          64'h2236_d88f_e561_8cf0,
          64'h0000_0000_8000_1260, 64'h0000_0000_8000_1280, 1'b0);
      run_v8n_muldiv_eight_younger(
          "v8n DIVU", 3'b101,
          64'hffff_ffff_ffff_ffff, 64'd3,
          64'h5555_5555_5555_5555,
          64'h0000_0000_8000_12c0, 64'h0000_0000_8000_12e0, 1'b1);
      tb_check32("v8n load metric", v8n_load_miss_completed, 32'd8);
      tb_check32("v8n MUL metric", v8n_mul_completed, 32'd8);
      tb_check32("v8n DIV metric", v8n_div_completed, 32'd8);
      tb_check1("v8n ROB peak at least nine", v8n_rob_peak >= 9, 1'b1);
      tb_check1("v8n real valid ROB peak at least nine",
                v8n_rob_valid_peak >= 9, 1'b1);
      tb_check32("v8n zero retire-order violations",
                 v8n_retire_order_violations, 32'd0);
      $display("[V8N-TRUE-OOO-METRICS] load_miss=%0d mul=%0d div=%0d rob_peak=%0d retire_order_violations=%0d",
               v8n_load_miss_completed, v8n_mul_completed,
               v8n_div_completed, v8n_rob_peak,
               v8n_retire_order_violations);
      $display("[V8N-TRUE-OOO-BINDING] load_issue=%0d mul_issue=%0d div_issue=%0d load_dual=%0d mul_dual=%0d div_dual=%0d load_owner_live_wb=%0d mul_owner_live_wb=%0d div_owner_live_wb=%0d rob_valid_peak=%0d",
               v8n_load_issue_accepted, v8n_mul_issue_accepted,
               v8n_div_issue_accepted, v8n_load_dual_issue_cycles,
               v8n_mul_dual_issue_cycles, v8n_div_dual_issue_cycles,
               v8n_load_owner_live_completions,
               v8n_mul_owner_live_completions,
               v8n_div_owner_live_completions, v8n_rob_valid_peak);
      $display("[V8N-TRUE-OOO-LONG-LATENCY] load-miss/mul/div exact-PID completion and ordered-retire PASS");
    end
  endtask

  task automatic run_v8s_reverse_bank_backpressure;
    reg [ROB_INDEX_W-1:0] bank0_rob;
    reg [ROB_INDEX_W-1:0] bank1_rob;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      // The older terminal maps to bank1 and the younger terminal to bank0.
      set_dispatch0(64'h0000_0000_8000_c300,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd8, 64'h0000_0000_0000_0608);
      set_dispatch1(64'h0000_0000_8000_c304,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd9, 64'h0000_0000_0000_0600);
      #1;
      tb_check1("V8S reverse dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8S reverse dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check64("V8S reverse bank0 gets younger address", mem_req_addr,
                 64'h0000_0000_0000_0600);
      tb_check64("V8S reverse bank1 gets older address", mem1_req_addr,
                 64'h0000_0000_0000_0608);
      // Only bank0 is ready: terminal1 must consume while terminal0 holds.
      mem_req_ready = 1'b1;
      #1;
      tb_check1("V8S terminal1-only bank0 fire", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8S terminal0 bank1 backpressured",
                dut.mem1_req_fire_any_w, 1'b0);
      tb_check1("V8S terminal0 reservation holds",
                dut.mem_issue_res_consume_fire_w, 1'b0);
      tb_check1("V8S terminal1-only consume",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S reverse terminal0 remains",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V8S reverse terminal1 drains",
                dut.mem_issue1_res_valid_q, 1'b0);
      tb_check1("V8S reverse bank0 does not steal held owner",
                mem_req_valid, 1'b0);
      tb_check1("V8S reverse bank1 valid survives peer fire",
                mem1_req_valid, 1'b1);
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S held bank1 request later fires",
                dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S reverse bank0 MIQ", dut.miq_count_w, 32'd1);
      tb_check32("V8S reverse bank1 MIQ", dut.miq1_count_w, 32'd1);
      bank0_rob = dut.miq_head_rob_w;
      bank1_rob = dut.miq1_head_rob_w;
      tb_check1("V8S reverse bank1 is older ROB",
                bank1_rob != bank0_rob, 1'b1);

      v8v_record_load_head_order(
          "V8S reverse", 1'b1, 64'h0000_0000_0000_0600,
          1'b1, 64'h0000_0000_0000_0608);

      // Create one real edge-old EX completion.  It owns WB0; bank0 memory
      // receives WB1 and bank1 must hold its valid until the next cycle.
      set_dispatch0(64'h0000_0000_8000_c308,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd10, 64'h55);
      #1;
      tb_check1("V8S reverse ALU dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8S reverse ALU issue live", dut.iq_issue0_valid_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_rdata = 64'hbbbb_0000_bbbb_0000;
      mem1_rsp_rdata = 64'haaaa_0000_aaaa_0000;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S reverse real EX occupies WB0", dut.ex0_wb_valid_w, 1'b1);
      tb_check1("V8S reverse bank0 response uses WB1",
                dut.mem_rsp_to_wb1_w, 1'b1);
      tb_check1("V8S reverse bank0 response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S reverse bank1 response held", mem1_rsp_ready, 1'b0);
      tb_check64("V8S reverse ALU WB0 data", dut.wb0_data_w, 64'h55);
      tb_check64("V8S reverse younger memory WB1 data", dut.wb1_data_w,
                 64'hbbbb_0000_bbbb_0000);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S reverse held bank1 response resumes", mem1_rsp_ready, 1'b1);
      tb_check1("V8S reverse bank1 response gets WB0",
                dut.mem1_rsp_to_wb0_w, 1'b1);
      tb_check64("V8S reverse older memory WB0 data", dut.wb0_data_w,
                 64'haaaa_0000_aaaa_0000);
      `TB_TICK(clk);
      mem1_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S reverse ordered older commit", commit0_valid, 1'b1);
      tb_check1("V8S reverse ordered younger commit", commit1_valid, 1'b1);
      tb_check64("V8S reverse older commit data", commit0_data,
                 64'haaaa_0000_aaaa_0000);
      tb_check64("V8S reverse younger commit data", commit1_data,
                 64'hbbbb_0000_bbbb_0000);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S reverse younger ALU commits", commit0_valid, 1'b1);
      tb_check64("V8S reverse younger ALU data", commit0_data, 64'h55);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S reverse ROB drains", rob_count, 32'd0);
      tb_check32("V8S reverse owner tracker drains",
                 dut.mem_owner_live_count_w, 32'd0);
      $display("[V8S-REVERSE-BACKPRESSURE] terminal1_only=1 real_one_credit=1 bank1_hold=1 ordered_retire=1 PASS");
    end
  endtask

  task automatic run_v8s_rob_wrap_age;
    integer pair_i;
    begin
      // Advance an empty ROB to head/tail 15 without forcing internal state.
      // The following same-bank pair then owns raw indices 15 (older) and 0
      // (younger), so a raw-index comparison selects the wrong reservation.
      reset_dut();
      for (pair_i = 0; pair_i < 7; pair_i = pair_i + 1) begin
        set_dispatch0(64'h0000_0000_8000_c700 + (pair_i * 8),
                      make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                      5'd0, 5'd0, 5'd30, 64'h100 + pair_i);
        set_dispatch1(64'h0000_0000_8000_c704 + (pair_i * 8),
                      make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                    `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                      5'd0, 5'd0, 5'd31, 64'h200 + pair_i);
        tick_dispatch_to_commit("V8S ROB-wrap pair prime",
                                64'h100 + pair_i, 64'h200 + pair_i);
      end
      tb_check32("V8S ROB-wrap head reaches fourteen",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w}, 32'd14);

      set_dispatch0(64'h0000_0000_8000_c738,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd29, 64'h5e);
      #1;
      tb_check1("V8S ROB-wrap single prime dispatch", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("V8S ROB-wrap single prime ROB", rob_count, 32'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S ROB-wrap single prime WB", dut.wb0_valid_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S ROB-wrap single prime commit", commit0_valid, 1'b1);
      tb_check64("V8S ROB-wrap single prime data", commit0_data, 64'h5e);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S ROB-wrap prime drains", rob_count, 32'd0);
      tb_check32("V8S ROB-wrap head reaches fifteen",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w}, 32'd15);

      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c740,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd27, 64'h0000_0000_0000_0a00);
      set_dispatch1(64'h0000_0000_8000_c744,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd28, 64'h0000_0000_0000_0a20);
      #1;
      tb_check1("V8S ROB-wrap load0 dispatch", dispatch0_ready, 1'b1);
      tb_check1("V8S ROB-wrap load1 dispatch", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check32("V8S ROB-wrap older raw index",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue_res_rob_idx_q},
                 32'd15);
      tb_check32("V8S ROB-wrap younger raw index",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.mem_issue1_res_rob_idx_q},
                 32'd0);
      tb_check32("V8S ROB-wrap arbitration head",
                 {{(32-ROB_INDEX_W){1'b0}}, dut.rob_head_idx_w}, 32'd15);
      tb_check64("V8S ROB-wrap older selected across zero", mem_req_addr,
                 64'h0000_0000_0000_0a00);
      tb_check1("V8S ROB-wrap same-bank peer idle", mem1_req_valid, 1'b0);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S ROB-wrap older consumes first",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("V8S ROB-wrap younger holds first",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check64("V8S ROB-wrap younger follows", mem_req_addr,
                 64'h0000_0000_0000_0a20);
      tb_check1("V8S ROB-wrap younger consumes second",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S ROB-wrap same-bank MIQ depth", dut.miq_count_w, 32'd2);

      v8v_record_load_head_order(
          "V8S ROB-wrap older", 1'b1, 64'h0000_0000_0000_0a00,
          1'b0, {`XLEN{1'b0}});

      mem_rsp_rdata = 64'hf00f_0000_0000_000f;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S ROB-wrap older response", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S ROB-wrap older commit", commit0_valid, 1'b1);
      tb_check64("V8S ROB-wrap older commit data", commit0_data,
                 64'hf00f_0000_0000_000f);
      v8v_record_load_head_order(
          "V8S ROB-wrap younger", 1'b1, 64'h0000_0000_0000_0a20,
          1'b0, {`XLEN{1'b0}});
      mem_rsp_rdata = 64'h0000_0000_0000_0001;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S ROB-wrap younger response", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S ROB-wrap younger commit", commit0_valid, 1'b1);
      tb_check64("V8S ROB-wrap younger commit data", commit0_data, 64'h1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S ROB-wrap pair drains", rob_count, 32'd0);
      tb_check32("V8S ROB-wrap MIQ drains", dut.miq_count_w, 32'd0);
      $display("[V8S-ROB-WRAP-AGE] head=15 older=15 younger=0 ordered=1 PASS");
    end
  endtask

  task automatic run_v8s_dual_ex_wb_hold;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c800,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd20, 64'h0000_0000_0000_0b00);
      set_dispatch1(64'h0000_0000_8000_c804,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd21, 64'h0000_0000_0000_0b08);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S dual-EX seed bank0 fire", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8S dual-EX seed bank1 fire", dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S dual-EX bank0 MIQ", dut.miq_count_w, 32'd1);
      tb_check32("V8S dual-EX bank1 MIQ", dut.miq1_count_w, 32'd1);

      v8v_record_load_head_order(
          "V8S dual-EX", 1'b1, 64'h0000_0000_0000_0b00,
          1'b1, 64'h0000_0000_0000_0b08);

      set_dispatch0(64'h0000_0000_8000_c808,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd22, 64'h62);
      set_dispatch1(64'h0000_0000_8000_c80c,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd23, 64'h63);
      #1;
      tb_check1("V8S dual-EX ALU0 dispatch", dispatch0_ready, 1'b1);
      tb_check1("V8S dual-EX ALU1 dispatch", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_rsp_rdata = 64'hd000_0000_0000_0000;
      mem1_rsp_rdata = 64'hd111_1111_1111_1111;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S dual-EX occupies WB0", dut.ex0_wb_valid_w, 1'b1);
      tb_check1("V8S dual-EX occupies WB1", dut.ex1_wb_valid_w, 1'b1);
      tb_check1("V8S dual-EX holds bank0 response", mem_rsp_ready, 1'b0);
      tb_check1("V8S dual-EX holds bank1 response", mem1_rsp_ready, 1'b0);
      tb_check1("V8S dual-EX no bank0 WB claim", dut.mem_wb_fire_w, 1'b0);
      tb_check1("V8S dual-EX no bank1 WB claim", dut.mem1_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S dual-EX released bank0 response", mem_rsp_ready, 1'b1);
      tb_check1("V8S dual-EX released bank1 response", mem1_rsp_ready, 1'b1);
      tb_check1("V8S dual-EX bank0 owns WB0", dut.mem_rsp_to_wb0_w, 1'b1);
      tb_check1("V8S dual-EX bank1 owns WB1", dut.mem1_rsp_to_wb1_w, 1'b1);
      tb_check64("V8S dual-EX held bank0 data", dut.wb0_data_w,
                 64'hd000_0000_0000_0000);
      tb_check64("V8S dual-EX held bank1 data", dut.wb1_data_w,
                 64'hd111_1111_1111_1111);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S dual-EX memory commit0", commit0_valid, 1'b1);
      tb_check1("V8S dual-EX memory commit1", commit1_valid, 1'b1);
      tb_check64("V8S dual-EX memory commit0 data", commit0_data,
                 64'hd000_0000_0000_0000);
      tb_check64("V8S dual-EX memory commit1 data", commit1_data,
                 64'hd111_1111_1111_1111);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S dual-EX ALU commit0", commit0_valid, 1'b1);
      tb_check1("V8S dual-EX ALU commit1", commit1_valid, 1'b1);
      tb_check64("V8S dual-EX ALU commit0 data", commit0_data, 64'h62);
      tb_check64("V8S dual-EX ALU commit1 data", commit1_data, 64'h63);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S dual-EX ROB drains", rob_count, 32'd0);
      tb_check32("V8S dual-EX bank0 MIQ drains", dut.miq_count_w, 32'd0);
      tb_check32("V8S dual-EX bank1 MIQ drains", dut.miq1_count_w, 32'd0);
      $display("[V8S-DUAL-EX-WB-HOLD] ex_slots=2 held=2 resumed=2 exactly_once=1 PASS");
    end
  endtask

  task automatic run_v8s_dual_store_probe;
    integer wait_i;
    begin
      // Two successful probes consume two response ports and two SQ fill ports,
      // but no WB or ROB terminal.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c400,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0700);
      set_dispatch1(64'h0000_0000_8000_c404,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0708);
      #1;
      tb_check1("V8S dual-store dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8S dual-store dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S dual-store bank0 probe fire", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8S dual-store bank1 probe fire", dut.mem1_req_fire_any_w, 1'b1);
      tb_check1("V8S dual-store bank0 is probe", mem_req_probe, 1'b1);
      tb_check1("V8S dual-store bank1 is probe", mem1_req_probe, 1'b1);
      tb_check1("V8S dual-store semantic write0", mem_req_write, 1'b1);
      tb_check1("V8S dual-store semantic write1", mem1_req_write, 1'b1);
      tb_check1("V8S dual-store probe0 is not pretranslated",
                mem_req_pretrans, 1'b0);
      tb_check1("V8S dual-store probe1 is not pretranslated",
                mem1_req_pretrans, 1'b0);
      tb_check1("V8S dual-store probe0 remains killable", mem_req_nokill, 1'b0);
      tb_check1("V8S dual-store probe1 remains killable", mem1_req_nokill, 1'b0);
      `TB_TICK(clk);
      mem_rsp_rdata = 64'h0000_0000_9000_0700;
      mem1_rsp_rdata = 64'h0000_0000_a000_0708;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S dual-store bank0 response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S dual-store bank1 response ready", mem1_rsp_ready, 1'b1);
      tb_check1("V8S dual-store fill0", dut.sq_fill_valid_w, 1'b1);
      tb_check1("V8S dual-store fill1", dut.sq_fill1_valid_w, 1'b1);
      tb_check64("V8S dual-store fill0 PA", dut.sq_fill_paddr_w,
                 64'h0000_0000_9000_0700);
      tb_check64("V8S dual-store fill1 PA", dut.sq_fill1_paddr_w,
                 64'h0000_0000_a000_0708);
      tb_check1("V8S dual-store success no WB0", dut.wb0_valid_w, 1'b0);
      tb_check1("V8S dual-store success no WB1", dut.wb1_valid_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      wait_i = 0;
      while ((dut.mem_owner_live_count_w != 0) && (wait_i < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8S dual-store success SQ flushes", dut.sq_count_w, 32'd0);
      tb_check32("V8S dual-store success owners free",
                 dut.mem_owner_live_count_w, 32'd0);

      // Two probe faults require both global WB slots and both SQ terminal
      // ports in the same cycle; neither may masquerade as an SQ fill.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c420,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0720);
      set_dispatch1(64'h0000_0000_8000_c424,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0728);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      `TB_TICK(clk);
      mem_rsp_error = 1'b1;
      mem1_rsp_error = 1'b1;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S dual-store fault0 response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S dual-store fault1 response ready", mem1_rsp_ready, 1'b1);
      tb_check1("V8S dual-store fault WB0", dut.wb0_valid_w, 1'b1);
      tb_check1("V8S dual-store fault WB1", dut.wb1_valid_w, 1'b1);
      tb_check1("V8S dual-store fault terminal0",
                dut.sq_terminal0_valid_w, 1'b1);
      tb_check1("V8S dual-store fault terminal1",
                dut.sq_terminal1_valid_w, 1'b1);
      tb_check1("V8S dual-store fault no fill0", dut.sq_fill_valid_w, 1'b0);
      tb_check1("V8S dual-store fault no fill1", dut.sq_fill1_valid_w, 1'b0);
      tb_check1("V8S dual-store terminal tokens differ",
                dut.sq_terminal0_token_w != dut.sq_terminal1_token_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      mem1_rsp_error = 1'b0;
      flush = 1'b1;
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      wait_i = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8S dual-store fault SQ drains", dut.sq_count_w, 32'd0);
      tb_check32("V8S dual-store fault owners free",
                 dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8S dual-store fault collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      $display("[V8S-DUAL-STORE-PROBE] dual_fill=1 dual_fault_wb=1 dual_sq_terminal=1 ordinary_probe_only=1 physical_write=0 PASS");
    end
  endtask

  task automatic run_v8s_singleton_exclusion;
    reg [4:0] amo_token;
    integer wait_i;
    begin
      // Keep an AMO read live, then capture two ordinary loads behind it.
      seed_s2_g1_amo_read(64'h0000_0000_8000_c500, amo_token);
      set_dispatch0(64'h0000_0000_8000_c504,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd11, 64'h0000_0000_0000_0800);
      set_dispatch1(64'h0000_0000_8000_c508,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd12, 64'h0000_0000_0000_0808);
      #1;
      tb_check1("V8S singleton pair dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8S singleton pair dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8S singleton ordinary reservation0 captured",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V8S singleton ordinary reservation1 captured",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V8S live LEGACY blocks bank0 ordinary", mem_req_valid, 1'b0);
      tb_check1("V8S live LEGACY blocks bank1 ordinary", mem1_req_valid, 1'b0);

      // Successful AMO read creates the write-phase singleton.  Its next-edge
      // launch must atomically win over both ordinary bank candidates.
      mem_rsp_rdata = 64'h7;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S singleton AMO read response", dut.mem_amo_read_rsp_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S singleton AMO write grant", dut.grant_amo_write_w, 1'b1);
      tb_check1("V8S singleton write is physical", mem_req_write, 1'b1);
      tb_check1("V8S singleton blocks ordinary grant0",
                dut.grant_issue0_w || dut.grant_issue1_w, 1'b0);
      tb_check1("V8S singleton blocks ordinary grant1",
                dut.grant_mem1_issue0_w || dut.grant_mem1_issue1_w, 1'b0);
      tb_check1("V8S singleton no bank1 request", mem1_req_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S singleton write sent", dut.mem_amo_write_sent_q, 1'b1);
      tb_check32("V8S singleton LEGACY MIQ only", dut.miq_count_w, 32'd1);
      tb_check32("V8S singleton peer MIQ empty", dut.miq1_count_w, 32'd0);

      // On the final B edge, edge-old LEGACY ownership still closes both
      // ordinary admissions.  They become visible only one cycle later.
      mem_rsp_rdata = 64'h0;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S singleton final response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S singleton final response formal WB",
                dut.mem_wb_fire_w, 1'b1);
      tb_check1("V8S singleton release edge blocks bank1",
                mem1_req_valid, 1'b0);
      tb_check1("V8S singleton release edge is not ordinary bank0",
                dut.grant_issue0_w || dut.grant_issue1_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S singleton post-release bank0 ordinary", mem_req_valid, 1'b1);
      tb_check1("V8S singleton post-release bank1 ordinary", mem1_req_valid, 1'b1);
      tb_check1("V8S singleton post-release dual fire0",
                dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8S singleton post-release dual fire1",
                dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      v8v_record_load_head_order(
          "V8S singleton followers", 1'b1, 64'h0000_0000_0000_0800,
          1'b1, 64'h0000_0000_0000_0808);
      mem_rsp_rdata = 64'h81;
      mem1_rsp_rdata = 64'h82;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S singleton followers response0", mem_rsp_ready, 1'b1);
      tb_check1("V8S singleton followers response1", mem1_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      commit_ready = 1'b1;
      #1;
      wait_i = 0;
      while (((rob_count != 0) || (dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8S singleton ROB drains", rob_count, 32'd0);
      tb_check32("V8S singleton owners drain",
                 dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8S singleton collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      $display("[V8S-SINGLETON-EXCLUSION] amo_priority=1 both_miq_empty=1 release_lookthrough=0 post_release_dual=1 PASS");
    end
  endtask

  task automatic run_v8s_selective_kill_race;
    integer wait_i;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c600,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd13, 64'h0000_0000_0000_0900);
      set_dispatch1(64'h0000_0000_8000_c604,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd14, 64'h0000_0000_0000_0908);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      `TB_TICK(clk);
      #1;
      tb_check32("V8S selective-kill bank0 MIQ", dut.miq_count_w, 32'd1);
      tb_check32("V8S selective-kill bank1 MIQ", dut.miq1_count_w, 32'd1);

      v8v_record_load_head_order(
          "V8S selective-kill", 1'b1, 64'h0000_0000_0000_0900,
          1'b1, 64'h0000_0000_0000_0908);

      // Treat the older bank0 load as the branch boundary.  The bank1 load is
      // younger and must drain exact identity without any architectural sink.
      t3v_force_branch_rob = dut.miq_head_rob_w;
      force dut.branch_resolve_mispredict_w = 1'b1;
      force dut.branch_resolve_rob_idx_o = t3v_force_branch_rob;
      mem_rsp_rdata = 64'h9000_0000_0000_0001;
      mem1_rsp_rdata = 64'h9000_0000_0000_0002;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S selective-kill older bank0 survives",
                dut.miq_head_effective_killed_w, 1'b0);
      tb_check1("V8S selective-kill younger bank1 killed",
                dut.miq1_head_effective_killed_w, 1'b1);
      tb_check1("V8S selective-kill both transports drain",
                mem_rsp_ready && mem1_rsp_ready, 1'b1);
      tb_check1("V8S selective-kill older bank0 WB", dut.mem_wb_fire_w, 1'b1);
      tb_check1("V8S selective-kill bank1 no WB", dut.mem1_wb_fire_w, 1'b0);
      tb_check1("V8S selective-kill no WB1", dut.wb1_valid_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      release dut.branch_resolve_mispredict_w;
      release dut.branch_resolve_rob_idx_o;
      #1;
      wait_i = 0;
      while (((rob_count != 0) || (dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8S selective-kill ROB drains", rob_count, 32'd0);
      tb_check32("V8S selective-kill owners drain",
                 dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8S selective-kill collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      $display("[V8S-SELECTIVE-KILL-RACE] older_wb=1 younger_exact_drain=1 younger_wb=0 PASS");
    end
  endtask

  task automatic launch_v8v_checkpoint_physical_store;
    input [1023:0] label;
    input [`XLEN-1:0] store_pc;
    input [`XLEN-1:0] store_va;
    input [`XLEN-1:0] store_pa;
    integer wait_i;
    begin
      mem_translate_active = 1'b1;
      commit_ready = 1'b1;
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      set_dispatch0(store_pc, make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, store_va);
      dispatch0_inst = 32'h0000_3023;
      #1;
      tb_check1({label, " dispatch ready"}, dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();

      wait_mem0_request({label, " probe"}, 1'b1, store_va,
                        1'b0, {`XLEN{1'b0}}, 1'b0,
                        {`STRB_W{1'b0}});
      tb_check1({label, " request is probe"}, mem_req_probe, 1'b1);
      `TB_TICK(clk);

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = store_pa;
      mem_rsp_error = 1'b0;
      mem_rsp_cacheable = 1'b1;
      tb_mem_rsp_attr_valid = 1'b1;
      tb_mem_rsp_class = `OOO_MEM_CLASS_CACHED;
      #1;
      tb_check1({label, " probe response ready"}, mem_rsp_ready, 1'b1);
      tb_check1({label, " probe has no formal WB"},
                dut.mem_wb_fire_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;

      wait_i = 0;
      while (!mem_req_valid && (wait_i < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      check_mem0_request({label, " physical"}, 1'b1, store_pa,
                         1'b0, {`XLEN{1'b0}}, 1'b0,
                         {`STRB_W{1'b0}});
      tb_check1({label, " physical is not probe"}, mem_req_probe, 1'b0);
      tb_check1({label, " physical pretranslated"},
                mem_req_pretrans, 1'b1);
      tb_check1({label, " physical nokill"}, mem_req_nokill, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1({label, " physical request at most once"},
                mem_req_valid, 1'b0);
      tb_check32({label, " one physical request"},
                 v8v_checkpoint_phys_write_count_q, 32'd1);
      tb_check1({label, " irreversible PID lease live"},
                dut.checkpoint_irrevocable_write_q, 1'b1);
      tb_check32({label, " SQ request_sent live"},
                 dut.sq_snoop_request_sent_w, 32'd1);
      tb_check32({label, " ROB owner live"}, rob_count, 32'd1);
    end
  endtask

  task automatic run_v8v_checkpoint_restore_store_drain;
    localparam [`XLEN-1:0] DELAY_PC = 64'h0000_0000_8000_c680;
    localparam [`XLEN-1:0] DELAY_VA = 64'h0000_0000_4000_1680;
    localparam [`XLEN-1:0] DELAY_PA = 64'h0000_0000_8000_2680;
    localparam [`XLEN-1:0] EDGE_PC = 64'h0000_0000_8000_c690;
    localparam [`XLEN-1:0] EDGE_VA = 64'h0000_0000_4000_1690;
    localparam [`XLEN-1:0] EDGE_PA = 64'h0000_0000_8000_2690;
    reg [4:0] amo_token;
    integer wait_i;
    begin
      // Delayed OKAY B: raw restore becomes pending, blocks all new admission,
      // but preserves the exact DRAIN/ROB/SQ owner until B->WB->commit0->free.
      reset_dut();
      launch_v8v_checkpoint_physical_store(
          "V8V checkpoint delayed-B", DELAY_PC, DELAY_VA, DELAY_PA);

      // Seed a completed younger ROB entry before restore.  It must not retire
      // in lane1 beside the physical store; accepted recovery will discard it
      // only after the store's exact commit0/SQ release.
      set_dispatch0(64'h0000_0000_8000_c684,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'h22);
      dispatch0_inst = 32'h0220_0113;
      #1;
      tb_check1("V8V delayed-B younger seed dispatch",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      `TB_TICK(clk);
      #1;
      tb_check32("V8V delayed-B store plus younger ROB",
                 rob_count, 32'd2);
      tb_check1("V8V delayed-B younger completed behind store",
                dut.u_dispatch_backend.u_rob.done_q[1], 1'b1);
      tb_check1("V8V delayed-B younger cannot bypass store",
                commit0_valid, 1'b0);

      checkpoint_restore = 1'b1;
      #1;
      tb_check1("V8V delayed-B raw request does not apply",
                checkpoint_restore_apply, 1'b0);
      tb_check1("V8V delayed-B raw request blocks dispatch",
                dispatch0_ready, 1'b0);
      tb_check32("V8V delayed-B raw request keeps ROB",
                 rob_count, 32'd2);
      tb_check32("V8V delayed-B raw request keeps MIQ DRAIN",
                 dut.miq_count_w, 32'd1);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check1("V8V delayed-B pending latched",
                dut.checkpoint_restore_pending_q, 1'b1);
      tb_check1("V8V delayed-B pending still not apply",
                checkpoint_restore_apply, 1'b0);

      set_dispatch0(64'h0000_0000_8000_c686,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'h22);
      #1;
      tb_check1("V8V delayed-B pending blocks younger dispatch",
                dispatch0_ready, 1'b0);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("V8V delayed-B hold creates no younger ROB",
                 rob_count, 32'd2);
      tb_check32("V8V delayed-B hold creates no extra request",
                 v8v_checkpoint_phys_write_count_q, 32'd1);

      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("V8V delayed-B response ready while pending",
                mem_rsp_ready, 1'b1);
      tb_check1("V8V delayed-B owns formal WB",
                dut.miq_drain_wb_fire_w, 1'b1);
      tb_check1("V8V delayed-B cannot apply on response edge",
                checkpoint_restore_apply, 1'b0);
      tb_check1("V8V delayed-B has no response-edge commit",
                commit0_valid, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8V delayed-B commits from ROB Q", commit0_valid, 1'b1);
      tb_check1("V8V delayed-B commit is non-exception",
                commit0_exception, 1'b0);
      tb_check1("V8V delayed-B commit releases SQ",
                dut.sq_release_fire_w, 1'b1);
      tb_check1("V8V delayed-B blocks commit1", commit1_valid, 1'b0);
      tb_check1("V8V delayed-B still defers apply on release edge",
                checkpoint_restore_apply, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("V8V delayed-B SQ released", dut.sq_count_w, 32'd0);
      tb_check1("V8V delayed-B apply follows edge-old release",
                checkpoint_restore_apply, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V delayed-B apply is one cycle",
                checkpoint_restore_apply, 1'b0);
      tb_check1("V8V delayed-B pending clears",
                dut.checkpoint_restore_pending_q, 1'b0);
      tb_check32("V8V delayed-B physical request exactly once",
                 v8v_checkpoint_phys_write_count_q, 32'd1);
      tb_check32("V8V delayed-B response exactly once",
                 v8v_checkpoint_b_count_q, 32'd1);
      tb_check32("V8V delayed-B commit/SQ free exactly once",
                 v8v_checkpoint_store_release_count_q, 32'd1);
      tb_check32("V8V delayed-B restore apply exactly once",
                 v8v_checkpoint_apply_count_q, 32'd1);
      tb_check32("V8V delayed-B ROB recovered", rob_count, 32'd0);

      set_dispatch0(64'h0000_0000_8000_c688,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd3, 64'h33);
      dispatch0_inst = 32'h0330_0193;
      #1;
      tb_check1("V8V delayed-B post-restore redispatch",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_commit0_data64("V8V delayed-B post-restore retire",
                          64'h33, 16);
      $display("[V8V-CHECKPOINT-STORE-DELAYED-B] okay=1 request=1 b=1 commit=1 sq_free=1 apply=1 redispatch_retire=1 PASS");

      // Error B on the same cycle as raw restore.  The request edge must not
      // close ROB completion authority; the precise store exception retires
      // once before the accepted recovery pulse.
      reset_dut();
      launch_v8v_checkpoint_physical_store(
          "V8V checkpoint same-edge-B", EDGE_PC, EDGE_VA, EDGE_PA);
      checkpoint_restore = 1'b1;
      mem_rsp_valid = 1'b1;
      mem_rsp_error = 1'b1;
      #1;
      tb_check1("V8V same-edge error B ready", mem_rsp_ready, 1'b1);
      tb_check1("V8V same-edge error B formal WB",
                dut.miq_drain_wb_fire_w, 1'b1);
      tb_check1("V8V same-edge error B exception",
                dut.wb0_exception_w, 1'b1);
      tb_check32("V8V same-edge error B cause7",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, dut.wb0_cause_w},
                 {{(32-`TRAP_CAUSE_W){1'b0}},
                  `EXC_STORE_ACCESS_FAULT});
      tb_check64("V8V same-edge error B original VA",
                 dut.wb0_tval_w, EDGE_VA);
      tb_check1("V8V same-edge raw request cannot apply",
                checkpoint_restore_apply, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      mem_rsp_valid = 1'b0;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("V8V same-edge error commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("V8V same-edge error commit exception",
                commit0_exception, 1'b1);
      tb_check32("V8V same-edge error commit cause7",
                 {{(32-`TRAP_CAUSE_W){1'b0}}, commit0_cause},
                 {{(32-`TRAP_CAUSE_W){1'b0}},
                  `EXC_STORE_ACCESS_FAULT});
      tb_check64("V8V same-edge error commit original VA",
                 commit0_tval, EDGE_VA);
      tb_check1("V8V same-edge error releases SQ",
                dut.sq_release_fire_w, 1'b1);
      tb_check1("V8V same-edge error blocks commit1", commit1_valid, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V same-edge apply follows precise exception retire",
                checkpoint_restore_apply, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V same-edge apply is one cycle",
                checkpoint_restore_apply, 1'b0);
      tb_check32("V8V same-edge physical request exactly once",
                 v8v_checkpoint_phys_write_count_q, 32'd1);
      tb_check32("V8V same-edge response exactly once",
                 v8v_checkpoint_b_count_q, 32'd1);
      tb_check32("V8V same-edge commit/SQ free exactly once",
                 v8v_checkpoint_store_release_count_q, 32'd1);
      tb_check32("V8V same-edge restore apply exactly once",
                 v8v_checkpoint_apply_count_q, 32'd1);
      tb_check32("V8V same-edge SQ drained", dut.sq_count_w, 32'd0);
      tb_check32("V8V same-edge ROB recovered", rob_count, 32'd0);

      set_dispatch0(64'h0000_0000_8000_c698,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd4, 64'h44);
      dispatch0_inst = 32'h0440_0213;
      #1;
      tb_check1("V8V same-edge post-restore redispatch",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      wait_commit0_data64("V8V same-edge post-restore retire",
                          64'h44, 16);

      wait_i = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8V checkpoint store owners drain",
                 dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8V checkpoint store collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      $display("[V8V-CHECKPOINT-STORE-SAME-EDGE-B] error=1 request=1 b=1 precise_exception_commit=1 sq_free=1 apply=1 redispatch_retire=1 PASS");

      // The irrevocable lease is request-class agnostic.  An AMO write phase
      // therefore observes the same pending protocol even though it has no SQ
      // entry: final B/WB and ROB retirement must precede restore apply.
      seed_s2_g1_amo_read(64'h0000_0000_8000_c6a0, amo_token);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_0000_0055;
      mem_rsp_error = 1'b0;
      #1;
      tb_check1("V8V checkpoint AMO read response",
                dut.mem_amo_read_rsp_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      commit_ready = 1'b1;
      #1;
      tb_check1("V8V checkpoint AMO write request", mem_req_valid, 1'b1);
      tb_check1("V8V checkpoint AMO write class", mem_req_write, 1'b1);
      tb_check1("V8V checkpoint AMO write not probe", mem_req_probe, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V checkpoint AMO irreversible lease",
                dut.checkpoint_irrevocable_write_q, 1'b1);
      tb_check32("V8V checkpoint AMO one physical write",
                 v8v_checkpoint_phys_write_count_q, 32'd1);

      checkpoint_restore = 1'b1;
      #1;
      tb_check1("V8V checkpoint AMO raw restore deferred",
                checkpoint_restore_apply, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check1("V8V checkpoint AMO pending latched",
                dut.checkpoint_restore_pending_q, 1'b1);
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = {`XLEN{1'b0}};
      #1;
      tb_check1("V8V checkpoint AMO final response ready",
                mem_rsp_ready, 1'b1);
      tb_check1("V8V checkpoint AMO final formal WB",
                dut.mem_wb_fire_w, 1'b1);
      tb_check1("V8V checkpoint AMO final is not fatal",
                dut.mem_fatal_irrevocable_response_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8V checkpoint AMO commits from ROB Q",
                commit0_valid, 1'b1);
      tb_check1("V8V checkpoint AMO commit non-exception",
                commit0_exception, 1'b0);
      tb_check64("V8V checkpoint AMO commit old value",
                 commit0_data, 64'h55);
      tb_check1("V8V checkpoint AMO blocks commit1", commit1_valid, 1'b0);
      tb_check1("V8V checkpoint AMO release edge still defers apply",
                checkpoint_restore_apply, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V checkpoint AMO apply after retire",
                checkpoint_restore_apply, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V checkpoint AMO apply exactly one cycle",
                checkpoint_restore_apply, 1'b0);
      tb_check32("V8V checkpoint AMO response exactly once",
                 v8v_checkpoint_write_response_count_q, 32'd1);
      tb_check32("V8V checkpoint AMO retire exactly once",
                 v8v_checkpoint_write_retire_count_q, 32'd1);
      tb_check32("V8V checkpoint AMO apply exactly once",
                 v8v_checkpoint_apply_count_q, 32'd1);
      tb_check32("V8V checkpoint AMO ROB recovered", rob_count, 32'd0);
      tb_check32("V8V checkpoint AMO owner tracker drained",
                 dut.mem_owner_live_count_w, 32'd0);
      $display("[V8V-CHECKPOINT-AMO-WRITE-DRAIN] request=1 b=1 commit=1 apply=1 PASS");
      $display("[V8V-CHECKPOINT-IRREVOCABLE-WRITE] delayed_store_okay=1 same_edge_store_error=1 amo_write=1 request_exact=3 response_exact=3 commit_exact=3 sq_free_exact=2 apply_exact=3 redispatch_retire=2 PASS");
      reset_dut();
    end
  endtask

  task automatic run_v8v_checkpoint_restore_lq_drain;
    reg [PRODUCER_ID_W-1:0] pid0;
    reg [PRODUCER_ID_W-1:0] pid1;
    reg [1:0] kind0;
    reg [1:0] kind1;
    reg [4:0] token0;
    reg [4:0] token1;
    reg [1:0] epoch0;
    reg [1:0] epoch1;
    reg [`XLEN-1:0] tval0;
    reg [`XLEN-1:0] tval1;
    integer wait_i;
    begin
      // An unlaunched load is still jointly owned by ROB/IQ/LQ.  A standalone
      // checkpoint restore must retire that whole backend recovery domain on
      // one edge; clearing only LQ/transport would strand the live ROB uop.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c620,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd15, 64'h0000_0000_0000_0920);
      dispatch0_inst = 32'h0000_3783;
      #1;
      tb_check1("V8V checkpoint unlaunched dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("V8V checkpoint unlaunched ROB resident",
                 rob_count, 32'd1);
      tb_check32("V8V checkpoint unlaunched IQ resident",
                 issue_count, 32'd1);
      tb_check32("V8V checkpoint unlaunched LQ resident",
                 dut.lq_count_w, 32'd1);
      checkpoint_restore = 1'b1;
      #1;
      tb_check1("V8V checkpoint recovery blocks redispatch",
                dispatch0_ready, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check32("V8V checkpoint clears unlaunched ROB",
                 rob_count, 32'd0);
      tb_check32("V8V checkpoint clears unlaunched IQ",
                 issue_count, 32'd0);
      tb_check32("V8V checkpoint clears unlaunched LQ",
                 dut.lq_count_w, 32'd0);
      tb_check32("V8V checkpoint restores integer free list",
                 free_count, 32'd32);

      // The same recovery edge covers the store-order owner.  This store has
      // not issued a physical write, so SQ and ROB must clear together rather
      // than leave a request-eligible orphan after restore.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c630,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0930);
      dispatch0_inst = 32'h0000_3023;
      #1;
      tb_check1("V8V checkpoint unlaunched store dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("V8V checkpoint unlaunched SQ resident",
                 dut.sq_count_w, 32'd1);
      tb_check32("V8V checkpoint unlaunched store ROB resident",
                 rob_count, 32'd1);
      checkpoint_restore = 1'b1;
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check32("V8V checkpoint clears unlaunched SQ owner",
                 dut.sq_count_w, 32'd0);
      tb_check32("V8V checkpoint clears unlaunched store ROB",
                 rob_count, 32'd0);

      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c640,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd16, 64'h0000_0000_0000_0940);
      set_dispatch1(64'h0000_0000_8000_c644,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd17, 64'h0000_0000_0000_0948);
      #1;
      tb_check1("V8V checkpoint load0 dispatch ready", dispatch0_ready, 1'b1);
      tb_check1("V8V checkpoint load1 dispatch ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8V checkpoint bank0 launch", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8V checkpoint bank1 launch", dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      pid0 = dut.mem_completion_producer_id_w;
      pid1 = dut.mem1_completion_producer_id_w;
      kind0 = mem_expected_owner_kind;
      kind1 = mem1_expected_owner_kind;
      token0 = mem_expected_owner_token;
      token1 = mem1_expected_owner_token;
      epoch0 = mem_expected_mmu_epoch;
      epoch1 = mem1_expected_mmu_epoch;
      tval0 = mem_expected_fault_tval;
      tval1 = mem1_expected_fault_tval;
      tb_check32("V8V checkpoint LQ has two launched loads",
                 dut.lq_count_w, 32'd2);

      checkpoint_restore = 1'b1;
      #1;
      tb_check1("V8V checkpoint masks bank0 request", mem_req_valid, 1'b0);
      tb_check1("V8V checkpoint masks bank1 request", mem1_req_valid, 1'b0);
      `TB_TICK(clk);
      checkpoint_restore = 1'b0;
      #1;
      tb_check32("V8V checkpoint clears bank0 MIQ", dut.miq_count_w, 32'd0);
      tb_check32("V8V checkpoint clears bank1 MIQ", dut.miq1_count_w, 32'd0);
      tb_check32("V8V checkpoint retains two LQ tombstones",
                 dut.lq_count_w, 32'd2);
      tb_check32("V8V checkpoint clears launched-load ROB owners",
                 rob_count, 32'd0);
      tb_check32("V8V checkpoint clears launched-load IQ owners",
                 issue_count, 32'd0);
      tb_check1("V8V checkpoint retains bank0 full PID",
                dut.lq_producer_live_mask_w[pid0], 1'b1);
      tb_check1("V8V checkpoint retains bank1 full PID",
                dut.lq_producer_live_mask_w[pid1], 1'b1);

      tb_mem_drop0_owner_kind = kind0;
      tb_mem_drop0_owner_token = token0;
      tb_mem_drop0_mmu_epoch = epoch0;
      tb_mem_drop0_fault_tval = tval0;
      tb_mem1_drop0_owner_kind = kind1;
      tb_mem1_drop0_owner_token = token1;
      tb_mem1_drop0_mmu_epoch = epoch1;
      tb_mem1_drop0_fault_tval = tval1;
      tb_mem_drop0_valid = 1'b1;
      tb_mem1_drop0_valid = 1'b1;
      #1;
      tb_check1("V8V checkpoint bank0 exact drop ingress",
                dut.mem_terminal_ingress_valid_w[2], 1'b1);
      tb_check1("V8V checkpoint bank1 exact drop ingress",
                dut.mem_terminal_ingress_valid_w[4], 1'b1);
      `TB_TICK(clk);
      tb_mem_drop0_valid = 1'b0;
      tb_mem1_drop0_valid = 1'b0;
      #1;
      wait_i = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0) ||
              (dut.lq_count_w != 0)) && (wait_i < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8V checkpoint exact terminals drain LQ",
                 dut.lq_count_w, 32'd0);
      tb_check32("V8V checkpoint owners drain",
                 dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8V checkpoint collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      tb_check1("V8V checkpoint bank0 PID no ghost",
                dut.lq_producer_live_mask_w[pid0], 1'b0);
      tb_check1("V8V checkpoint bank1 PID no ghost",
                dut.lq_producer_live_mask_w[pid1], 1'b0);

      // Do not reset between terminal drain and redispatch.  This proves the
      // full-PID birth fence reopens and the recovered ROB/IQ/rename domain
      // can execute and retire a fresh uop rather than merely reaching zero.
      commit_ready = 1'b1;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c650,
                    make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                  `ALU_OP_ADD, 1'b0, 1'b0, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h0000_0000_0000_005a);
      dispatch0_inst = 32'h05a0_0093;
      #1;
      tb_check1("V8V checkpoint post-drain redispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      wait_commit0_data64("V8V checkpoint post-drain redispatch",
                          64'h0000_0000_0000_005a, 16);
      $display("[V8V-CHECKPOINT-LQ-DRAIN] launched=2 tombstones=2 exact_terminals=2 ghosts=0 PASS");
      $display("[V8V-CHECKPOINT-OWNER-RECOVERY] load_unlaunched_clear=1 sq_unlaunched_clear=1 launched_rob_clear=2 tombstones=2 exact_terminals=2 redispatch_retire=1 ghosts=0 PASS");
      reset_dut();
    end
  endtask

  task automatic run_v8v_lq_retire_authority;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c660,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd18, 64'h0000_0000_0000_0c00);
      // The retirement classifier consumes the architectural instruction
      // carried by the ROB.  Keep this focused vector as an explicit LD,
      // rather than the generic helper's PC-as-instruction sentinel.
      dispatch0_inst = 32'h0000_3903;
      #1;
      tb_check1("V8V retire authority dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      #1;
      tb_check1("V8V retire authority request fire",
                dut.mem_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8V retire authority MIQ resident", dut.miq_count_w, 32'd1);
      v8v_record_load_head_order(
          "V8V retire authority", 1'b1, 64'h0000_0000_0000_0c00,
          1'b0, {`XLEN{1'b0}});

      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'hcafe_0000_0000_0066;
      #1;
      tb_check1("V8V retire authority response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8V retire authority formal WB", dut.wb0_valid_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8V retire lookup is exact and completed",
                dut.lq_release0_valid_w && dut.lq_release0_ready_w, 1'b1);

      force dut.lq_release0_ready_w = 1'b0;
      commit_ready = 1'b1;
      #1;
      tb_check1("V8V LQ retire authority blocks ROB commit",
                commit0_valid, 1'b0);
      tb_check32("V8V LQ retire authority retains ROB",
                 rob_count, 32'd1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8V LQ blocked edge remains noncommitting",
                commit0_valid, 1'b0);
      release dut.lq_release0_ready_w;
      #1;
      tb_check1("V8V exact LQ permit releases ROB commit",
                commit0_valid, 1'b1);
      tb_check1("V8V ROB commit and LQ free coincide",
                dut.lq_release0_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8V retire authority ROB drains", rob_count, 32'd0);
      tb_check32("V8V retire authority LQ drains", dut.lq_count_w, 32'd0);
      $display("[V8V-LQ-RETIRE-AUTHORITY] lookup_ready_gates_commit=1 commit_free_coincident=1 PASS");
      reset_dut();
    end
  endtask

`ifdef V11L_MEMORY_RETRY_HOLDER_FOCUSED
  task automatic v11l_oracle_fail;
    input [1023:0] stage;
    begin
      $display("[V11L-RETRY-HOLDER-ORACLE][FAIL] stage=%0s @%0t",
               stage, $time);
      $fatal(1);
    end
  endtask

  task automatic v11l_check_tracker0_live;
    begin
      if ((dut.mem_owner_live_mask_w[V11L_TOKEN0] !== 1'b1) ||
          (dut.mem_owner_kind_table_w[
              V11L_TOKEN0*2 +: 2] !== V11L_LOAD_KIND) ||
          (dut.mem_owner_epoch_table_w[
              V11L_TOKEN0*2 +: 2] !== V11L_EPOCH) ||
          (dut.mem_owner_producer_id_table_w[
              V11L_TOKEN0*PRODUCER_ID_W +: PRODUCER_ID_W] !==
           V11L_PID0))
        v11l_oracle_fail("tracker0-not-exact-live");
    end
  endtask

  task automatic v11l_check_tracker1_live;
    begin
      if ((dut.mem_owner_live_mask_w[V11L_TOKEN1] !== 1'b1) ||
          (dut.mem_owner_kind_table_w[
              V11L_TOKEN1*2 +: 2] !== V11L_LOAD_KIND) ||
          (dut.mem_owner_epoch_table_w[
              V11L_TOKEN1*2 +: 2] !== V11L_EPOCH) ||
          (dut.mem_owner_producer_id_table_w[
              V11L_TOKEN1*PRODUCER_ID_W +: PRODUCER_ID_W] !==
           V11L_PID1))
        v11l_oracle_fail("tracker1-not-exact-live");
    end
  endtask

  task automatic v11l_check_retry0_tuple;
    begin
      if ((dut.mem_retry0_valid_q !== 1'b1) ||
          (dut.mem_retry0_producer_id_q !== V11L_PID0) ||
          (dut.mem_retry0_owner_token_q !== V11L_TOKEN0) ||
          (dut.mem_retry0_owner_kind_q !== V11L_LOAD_KIND) ||
          (dut.mem_retry0_mmu_epoch_q !== V11L_EPOCH) ||
          (dut.mem_retry0_fault_tval_q !== V11L_ADDR0) ||
          (dut.mem_retry0_addr_q !== V11L_ADDR0) ||
          (dut.mem_retry0_size_q !== `MEM_SIZE_DWORD) ||
          (dut.mem_retry0_unsigned_q !== 1'b1) ||
          (dut.mem_retry0_wdata_q !== {`XLEN{1'b0}}) ||
          (dut.mem_retry0_wstrb_q !== {`STRB_W{1'b1}})) begin
        $display("[V11L-RETRY0-TUPLE-DIAG] valid=%b pid=%h token=%h kind=%h epoch=%h tval=%h addr=%h size=%h unsigned=%b wdata=%h wstrb=%h",
                 dut.mem_retry0_valid_q,
                 dut.mem_retry0_producer_id_q,
                 dut.mem_retry0_owner_token_q,
                 dut.mem_retry0_owner_kind_q,
                 dut.mem_retry0_mmu_epoch_q,
                 dut.mem_retry0_fault_tval_q,
                 dut.mem_retry0_addr_q,
                 dut.mem_retry0_size_q,
                 dut.mem_retry0_unsigned_q,
                 dut.mem_retry0_wdata_q,
                 dut.mem_retry0_wstrb_q);
        v11l_oracle_fail("retry0-holder-tuple");
      end
    end
  endtask

  task automatic v11l_check_retry1_tuple;
    begin
      if ((dut.mem_retry1_valid_q !== 1'b1) ||
          (dut.mem_retry1_producer_id_q !== V11L_PID1) ||
          (dut.mem_retry1_owner_token_q !== V11L_TOKEN1) ||
          (dut.mem_retry1_owner_kind_q !== V11L_LOAD_KIND) ||
          (dut.mem_retry1_mmu_epoch_q !== V11L_EPOCH) ||
          (dut.mem_retry1_fault_tval_q !== V11L_ADDR1) ||
          (dut.mem_retry1_addr_q !== V11L_ADDR1) ||
          (dut.mem_retry1_size_q !== `MEM_SIZE_WORD) ||
          (dut.mem_retry1_unsigned_q !== 1'b0) ||
          (dut.mem_retry1_wdata_q !== {`XLEN{1'b0}}) ||
          (dut.mem_retry1_wstrb_q !== 8'h0f)) begin
        $display("[V11L-RETRY1-TUPLE-DIAG] valid=%b pid=%h token=%h kind=%h epoch=%h tval=%h addr=%h size=%h unsigned=%b wdata=%h wstrb=%h",
                 dut.mem_retry1_valid_q,
                 dut.mem_retry1_producer_id_q,
                 dut.mem_retry1_owner_token_q,
                 dut.mem_retry1_owner_kind_q,
                 dut.mem_retry1_mmu_epoch_q,
                 dut.mem_retry1_fault_tval_q,
                 dut.mem_retry1_addr_q,
                 dut.mem_retry1_size_q,
                 dut.mem_retry1_unsigned_q,
                 dut.mem_retry1_wdata_q,
                 dut.mem_retry1_wstrb_q);
        v11l_oracle_fail("retry1-holder-tuple");
      end
    end
  endtask

  task automatic v11l_seed_dual_retry_holders;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      // The first reset-domain allocations have fully specified, distinct
      // ProducerIds and owner tokens.  Address bit 3 routes one LOAD to each
      // physical memory bank; size/unsigned/address also remain lane-distinct.
      set_dispatch0(64'h0000_0000_8001_1000,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd14, V11L_ADDR0);
      set_dispatch1(64'h0000_0000_8001_1004,
                    make_load_ctrl(`MEM_SIZE_WORD, 1'b0),
                    5'd0, 5'd0, 5'd15, V11L_ADDR1);
      #1;
      if ((dispatch0_ready !== 1'b1) ||
          (dispatch1_ready !== 1'b1) ||
          (dispatch0_producer_id !== V11L_PID0) ||
          (dut.dispatch1_producer_id_w !== V11L_PID1) ||
          (V11L_PID0 === V11L_PID1) ||
          (V11L_TOKEN0 === V11L_TOKEN1))
        v11l_oracle_fail("dual-dispatch-distinct-identity");
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;

      if ((mem_req_valid !== 1'b1) ||
          (mem1_req_valid !== 1'b1) ||
          (mem_req_write !== 1'b0) ||
          (mem1_req_write !== 1'b0) ||
          (mem_req_owner_token !== V11L_TOKEN0) ||
          (mem1_req_owner_token !== V11L_TOKEN1) ||
          (mem_req_owner_kind !== V11L_LOAD_KIND) ||
          (mem1_req_owner_kind !== V11L_LOAD_KIND) ||
          (mem_req_mmu_epoch !== V11L_EPOCH) ||
          (mem1_req_mmu_epoch !== V11L_EPOCH) ||
          (mem_req_addr !== V11L_ADDR0) ||
          (mem1_req_addr !== V11L_ADDR1))
        v11l_oracle_fail("dual-first-request-tuple");
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();

      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      if ((dut.mem_req_fire_any_w !== 1'b1) ||
          (dut.mem1_req_fire_any_w !== 1'b1) ||
          (dut.miq_push_valid_w !== 1'b1) ||
          (dut.miq1_push_valid_w !== 1'b1))
        v11l_oracle_fail("dual-first-request-fire");
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;

      if ((dut.miq_count_w !== 1) ||
          (dut.miq1_count_w !== 1) ||
          (dut.miq_head_owner_token_w !== V11L_TOKEN0) ||
          (dut.miq1_head_owner_token_w !== V11L_TOKEN1) ||
          (dut.miq_head_addr_w !== V11L_ADDR0) ||
          (dut.miq1_head_addr_w !== V11L_ADDR1))
        v11l_oracle_fail("dual-miq-source-tuple");

      mem_sq_query_valid = 1'b1;
      mem_sq_query_owner_kind = V11L_LOAD_KIND;
      mem_sq_query_owner_token = V11L_TOKEN0;
      mem_sq_query_mmu_epoch = V11L_EPOCH;
      mem_sq_query_paddr = V11L_PADDR0;
      mem_sq_query_attr_valid = 1'b1;
      mem_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem_sq_query_wstrb = {`STRB_W{1'b1}};
      mem1_sq_query_valid = 1'b1;
      mem1_sq_query_owner_kind = V11L_LOAD_KIND;
      mem1_sq_query_owner_token = V11L_TOKEN1;
      mem1_sq_query_mmu_epoch = V11L_EPOCH;
      mem1_sq_query_paddr = V11L_PADDR1;
      mem1_sq_query_attr_valid = 1'b1;
      mem1_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem1_sq_query_wstrb = {`STRB_W{1'b1}};

      // Isolate the holder from StoreQueue contents while retaining real
      // owner allocation, bank routing, MIQ heads and exact query matching.
      // The forced value represents the legal "older unfilled STORE" replay
      // decision already proven by V9R.
      force dut.sq_query0_allow_w = 1'b0;
      force dut.sq_query0_forward_w = 1'b0;
      force dut.sq_query0_replay_w = 1'b1;
      force dut.sq_query1_allow_w = 1'b0;
      force dut.sq_query1_forward_w = 1'b0;
      force dut.sq_query1_replay_w = 1'b1;
      force dut.control_full_flush_barrier_w = 1'b1;
      #1;
      if ((dut.mem_sq_query_exact_w !== 1'b1) ||
          (dut.mem1_sq_query_exact_w !== 1'b1) ||
          (mem_sq_query_replay !== 1'b1) ||
          (mem1_sq_query_replay !== 1'b1) ||
          (mem_sq_query_retry_ready !== 1'b0) ||
          (mem1_sq_query_retry_ready !== 1'b0) ||
          (dut.mem_sq_retry0_capture_w !== 1'b0) ||
          (dut.mem_sq_retry1_capture_w !== 1'b0))
        v11l_oracle_fail("c0-empty-holder-capture-barrier");
      `TB_TICK(clk);
      #1;
      if ((dut.miq_count_w !== 1) ||
          (dut.miq1_count_w !== 1) ||
          (dut.mem_retry0_valid_q !== 1'b0) ||
          (dut.mem_retry1_valid_q !== 1'b0))
        v11l_oracle_fail("c0-empty-holder-edge");
      release dut.control_full_flush_barrier_w;
      #1;

      if ((mem_sq_query_retry_ready !== 1'b1) ||
          (mem1_sq_query_retry_ready !== 1'b1) ||
          (dut.mem_sq_retry0_capture_w !== 1'b1) ||
          (dut.mem_sq_retry1_capture_w !== 1'b1) ||
          (dut.mem_terminal_ingress_mask_w[V11L_TOKEN0] !== 1'b0) ||
          (dut.mem_terminal_ingress_mask_w[V11L_TOKEN1] !== 1'b0))
        v11l_oracle_fail("dual-retry-capture");
      `TB_TICK(clk);
      mem_sq_query_valid = 1'b0;
      mem_sq_query_attr_valid = 1'b0;
      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = {`STRB_W{1'b0}};
      mem1_sq_query_valid = 1'b0;
      mem1_sq_query_attr_valid = 1'b0;
      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
      release dut.sq_query0_allow_w;
      release dut.sq_query0_forward_w;
      release dut.sq_query0_replay_w;
      release dut.sq_query1_allow_w;
      release dut.sq_query1_forward_w;
      release dut.sq_query1_replay_w;
      #1;

      if ((dut.miq_count_w !== 0) ||
          (dut.miq1_count_w !== 0))
        v11l_oracle_fail("dual-retry-capture-source-not-empty");
      v11l_check_retry0_tuple();
      v11l_check_retry1_tuple();
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      $display("[V11L-RETRY0-CAPTURE-TUPLE][PASS] pid=%0d token=%0d",
               V11L_PID0, V11L_TOKEN0);
      $display("[V11L-RETRY1-CAPTURE-TUPLE][PASS] pid=%0d token=%0d",
               V11L_PID1, V11L_TOKEN1);
      $display("[V11L-LANE-DISTINCT][PASS] pid0=%0d pid1=%0d token0=%0d token1=%0d",
               V11L_PID0, V11L_PID1, V11L_TOKEN0, V11L_TOKEN1);
    end
  endtask

  task automatic run_v11l_memory_retry_holder_semantic;
    integer hold_cycle;
    integer terminal_wait;
    begin
      v11l_seed_dual_retry_holders();

      // With both request lanes stalled, every retry field and both exact
      // owner leases must remain stable.  The source MIQs are already empty,
      // preventing a combinational source path from masquerading as storage.
      for (hold_cycle = 0; hold_cycle < 3;
           hold_cycle = hold_cycle + 1) begin
        #1;
        v11l_check_retry0_tuple();
        v11l_check_retry1_tuple();
        v11l_check_tracker0_live();
        v11l_check_tracker1_live();
        if ((dut.mem_retry0_req_fire_w !== 1'b0) ||
            (dut.mem_retry1_req_fire_w !== 1'b0) ||
            (dut.miq_push_valid_w !== 1'b0) ||
            (dut.miq1_push_valid_w !== 1'b0))
          v11l_oracle_fail("dual-backpressure-hold-event");
        `TB_TICK(clk);
      end
      $display("[V11L-RETRY-HOLD][PASS] cycles=3 source_miq_empty=1");

      // A filled holder must also pause under C0 even if both transport READY
      // inputs are asserted.  The full tuple remains resident and no re-push
      // is exposed until the barrier is removed.
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      force dut.control_full_flush_barrier_w = 1'b1;
      for (hold_cycle = 0; hold_cycle < 2;
           hold_cycle = hold_cycle + 1) begin
        #1;
        v11l_check_retry0_tuple();
        v11l_check_retry1_tuple();
        if ((mem_req_valid !== 1'b0) ||
            (mem1_req_valid !== 1'b0) ||
            (dut.mem_retry0_req_fire_w !== 1'b0) ||
            (dut.mem_retry1_req_fire_w !== 1'b0) ||
            (dut.miq_push_valid_w !== 1'b0) ||
            (dut.miq1_push_valid_w !== 1'b0))
          v11l_oracle_fail("c0-filled-holder-pause");
        `TB_TICK(clk);
      end
      release dut.control_full_flush_barrier_w;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      v11l_check_retry0_tuple();
      v11l_check_retry1_tuple();
      $display("[V11L-C0-HOLDER-PAUSE][PASS] cycles=2");

      // READY=10 transfers only bank0.  Before this edge both destination
      // MIQs are empty, so next-cycle occupancy cannot match a stale entry.
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b0;
      #1;
      if ((mem_req_valid !== 1'b1) ||
          (dut.mem_retry0_req_fire_w !== 1'b1) ||
          (dut.push_retry0_w !== 1'b1) ||
          (dut.mem_retry1_req_fire_w !== 1'b0) ||
          (dut.push_retry1_w !== 1'b0) ||
          (mem_req_owner_kind !== V11L_LOAD_KIND) ||
          (mem_req_owner_token !== V11L_TOKEN0) ||
          (mem_req_mmu_epoch !== V11L_EPOCH) ||
          (mem_req_fault_tval !== V11L_ADDR0) ||
          (mem_req_addr !== V11L_ADDR0) ||
          (dut.miq_push_owner_token_w !== V11L_TOKEN0))
        v11l_oracle_fail("retry0-fire-transfer");
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      if ((dut.mem_retry0_valid_q !== 1'b0) ||
          (dut.mem_retry1_valid_q !== 1'b1) ||
          (dut.miq_count_w !== 1) ||
          (dut.miq1_count_w !== 0) ||
          (dut.miq_head_owner_token_w !== V11L_TOKEN0) ||
          (dut.miq_occupancy_token_mask_w !==
           (32'b1 << V11L_TOKEN0)))
        v11l_oracle_fail("retry0-next-cycle-miq");
      v11l_check_retry1_tuple();
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      $display("[V11L-RETRY0-FIRE-TRANSFER][PASS] ready=10 occupancy=1");

      // READY=01 now transfers only bank1 while bank0 remains resident.
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b1;
      #1;
      if ((mem1_req_valid !== 1'b1) ||
          (dut.mem_retry1_req_fire_w !== 1'b1) ||
          (dut.push_retry1_w !== 1'b1) ||
          (dut.mem_retry0_req_fire_w !== 1'b0) ||
          (dut.push_retry0_w !== 1'b0) ||
          (mem1_req_owner_kind !== V11L_LOAD_KIND) ||
          (mem1_req_owner_token !== V11L_TOKEN1) ||
          (mem1_req_mmu_epoch !== V11L_EPOCH) ||
          (mem1_req_fault_tval !== V11L_ADDR1) ||
          (mem1_req_addr !== V11L_ADDR1) ||
          (dut.miq1_push_owner_token_w !== V11L_TOKEN1))
        v11l_oracle_fail("retry1-fire-transfer");
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      `TB_TICK(clk);
      mem1_req_ready = 1'b0;
      #1;
      if ((dut.mem_retry0_valid_q !== 1'b0) ||
          (dut.mem_retry1_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 1) ||
          (dut.miq1_count_w !== 1) ||
          (dut.miq1_head_owner_token_w !== V11L_TOKEN1) ||
          (dut.miq1_occupancy_token_mask_w !==
           (32'b1 << V11L_TOKEN1)))
        v11l_oracle_fail("retry1-next-cycle-miq");
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      $display("[V11L-RETRY1-FIRE-TRANSFER][PASS] ready=01 occupancy=1");

      // The first final-PA query deliberately recorded REPLAY in the LQ.
      // After retry re-push, emulate the bridge's second exact final-PA query
      // with ALLOW so both LQ entries become response-ordered.  This is a
      // distinct transfer phase; it does not recreate either retry holder.
      mem_sq_query_valid = 1'b1;
      mem_sq_query_owner_kind = V11L_LOAD_KIND;
      mem_sq_query_owner_token = V11L_TOKEN0;
      mem_sq_query_mmu_epoch = V11L_EPOCH;
      mem_sq_query_paddr = V11L_PADDR0;
      mem_sq_query_attr_valid = 1'b1;
      mem_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem_sq_query_wstrb = {`STRB_W{1'b1}};
      mem1_sq_query_valid = 1'b1;
      mem1_sq_query_owner_kind = V11L_LOAD_KIND;
      mem1_sq_query_owner_token = V11L_TOKEN1;
      mem1_sq_query_mmu_epoch = V11L_EPOCH;
      mem1_sq_query_paddr = V11L_PADDR1;
      mem1_sq_query_attr_valid = 1'b1;
      mem1_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem1_sq_query_wstrb = {`STRB_W{1'b1}};
      force dut.sq_query0_allow_w = 1'b1;
      force dut.sq_query0_forward_w = 1'b0;
      force dut.sq_query0_replay_w = 1'b0;
      force dut.sq_query1_allow_w = 1'b1;
      force dut.sq_query1_forward_w = 1'b0;
      force dut.sq_query1_replay_w = 1'b0;
      #1;
      if ((dut.mem_sq_query_exact_w !== 1'b1) ||
          (dut.mem1_sq_query_exact_w !== 1'b1) ||
          (mem_sq_query_allow !== 1'b1) ||
          (mem1_sq_query_allow !== 1'b1) ||
          (mem_sq_query_replay !== 1'b0) ||
          (mem1_sq_query_replay !== 1'b0) ||
          (dut.lq_query0_update_w !== 1'b1) ||
          (dut.lq_query1_update_w !== 1'b1))
        v11l_oracle_fail("dual-retry-second-query-allow");
      `TB_TICK(clk);
      mem_sq_query_valid = 1'b0;
      mem_sq_query_attr_valid = 1'b0;
      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = {`STRB_W{1'b0}};
      mem1_sq_query_valid = 1'b0;
      mem1_sq_query_attr_valid = 1'b0;
      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
      release dut.sq_query0_allow_w;
      release dut.sq_query0_forward_w;
      release dut.sq_query0_replay_w;
      release dut.sq_query1_allow_w;
      release dut.sq_query1_forward_w;
      release dut.sq_query1_replay_w;
      #1;
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();

      // Both trackers remain live through capture, hold, request fire and MIQ
      // residency.  Only exact response collector acceptance may terminate
      // them.
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1111_0000_0000_0000;
      mem1_rsp_rdata = 64'h2222_0000_0000_0001;
      #1;
      if ((mem_rsp_ready !== 1'b1) ||
          (mem1_rsp_ready !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[0] !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[1] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[0] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[1] !== 1'b1) ||
          (dut.mem_terminal_ingress0_mask_w !==
           (32'b1 << V11L_TOKEN0)) ||
          (dut.mem_terminal_ingress1_mask_w !==
           (32'b1 << V11L_TOKEN1))) begin
        $display("[V11L-RESPONSE-DIAG] ready=%b/%b barrier=%b pop_match=%b/%b tracker=%b/%b rob_open=%b/%b killed=%b/%b done=%b/%b base_open=%b/%b lq_open=%b/%b owner_open=%b/%b terminal_credit=%b/%b sink_credit=%b/%b wb_credit=%b/%b ingress=%b/%b accept=%b/%b mask0=%h mask1=%h miq=%0d/%0d",
                 mem_rsp_ready, mem1_rsp_ready,
                 dut.control_full_flush_barrier_w,
                 dut.miq_pop_owner_match_w,
                 dut.miq1_pop_owner_match_w,
                 dut.miq_head_tracker_exact_w,
                 dut.miq1_head_tracker_exact_w,
                 dut.mem_completion_rob_open_w,
                 dut.mem1_completion_rob_open_w,
                 dut.miq_head_effective_killed_w,
                 dut.miq1_head_effective_killed_w,
                 dut.mem_completion_done_now_w,
                 dut.mem1_completion_done_now_w,
                 dut.mem_owner_base_open_w,
                 dut.mem1_owner_base_open_w,
                 dut.lq_response0_open_w,
                 dut.lq_response1_open_w,
                 dut.mem_owner_open_w,
                 dut.mem1_owner_open_w,
                 dut.mem_response_terminal_credit_w,
                 dut.mem1_response_terminal_credit_w,
                 dut.mem_open_nonwb_sink_credit_w,
                 dut.mem1_open_nonwb_sink_credit_w,
                 dut.mem_wb_route_credit_w,
                 dut.mem1_wb_route_credit_w,
                 dut.mem_terminal_ingress_valid_w[0],
                 dut.mem_terminal_ingress_valid_w[1],
                 dut.mem_terminal_ingress_accept_w[0],
                 dut.mem_terminal_ingress_accept_w[1],
                 dut.mem_terminal_ingress0_mask_w,
                 dut.mem_terminal_ingress1_mask_w,
                 dut.miq_count_w, dut.miq1_count_w);
        v11l_oracle_fail("dual-response-terminal-accept");
      end
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      #1;
      if ((dut.mem_terminal_ingress_valid_w[0] !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[1] !== 1'b0))
        v11l_oracle_fail("dual-response-terminal-repeated");
      terminal_wait = 0;
      while (((dut.mem_owner_live_mask_w[V11L_TOKEN0] === 1'b1) ||
              (dut.mem_owner_live_mask_w[V11L_TOKEN1] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[V11L_TOKEN0] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[V11L_TOKEN1] === 1'b1)) &&
             (terminal_wait < 8)) begin
        `TB_TICK(clk);
        #1;
        terminal_wait = terminal_wait + 1;
      end
      if ((dut.mem_owner_live_mask_w[V11L_TOKEN0] !== 1'b0) ||
          (dut.mem_owner_live_mask_w[V11L_TOKEN1] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[V11L_TOKEN0] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[V11L_TOKEN1] !== 1'b0))
        v11l_oracle_fail("dual-response-terminal-death");
      $display("[V11L-RESPONSE-TERMINAL-EXACT][PASS] lanes=2 wait=%0d",
               terminal_wait);

      // Rebuild both holders, then overlap global pipeline flush with READY=11.
      // Cancel must dominate transport: lanes10/11 are the sole exact holder
      // terminals and neither LOAD may be re-pushed into an MIQ.
      v11l_seed_dual_retry_holders();
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      flush = 1'b1;
      #1;
      if ((dut.mem_retry0_cancel_w !== 1'b1) ||
          (dut.mem_retry1_cancel_w !== 1'b1) ||
          (mem_req_valid !== 1'b0) ||
          (mem1_req_valid !== 1'b0) ||
          (dut.mem_retry0_req_fire_w !== 1'b0) ||
          (dut.mem_retry1_req_fire_w !== 1'b0) ||
          (dut.miq_push_valid_w !== 1'b0) ||
          (dut.miq1_push_valid_w !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[10] !== 1'b1) ||
          (dut.mem_terminal_ingress_valid_w[11] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[10] !== 1'b1) ||
          (dut.mem_terminal_ingress_accept_w[11] !== 1'b1) ||
          (dut.mem_terminal_ingress_token_w[10*5 +: 5] !==
           V11L_TOKEN0) ||
          (dut.mem_terminal_ingress_token_w[11*5 +: 5] !==
           V11L_TOKEN1) ||
          (dut.mem_terminal_ingress_kind_w[10*2 +: 2] !==
           V11L_LOAD_KIND) ||
          (dut.mem_terminal_ingress_kind_w[11*2 +: 2] !==
           V11L_LOAD_KIND) ||
          (dut.mem_terminal_ingress_epoch_w[10*2 +: 2] !==
           V11L_EPOCH) ||
          (dut.mem_terminal_ingress_epoch_w[11*2 +: 2] !==
           V11L_EPOCH))
        v11l_oracle_fail("flush-cancel-terminal-priority");
      v11l_check_tracker0_live();
      v11l_check_tracker1_live();
      `TB_TICK(clk);
      flush = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      if ((dut.mem_retry0_valid_q !== 1'b0) ||
          (dut.mem_retry1_valid_q !== 1'b0) ||
          (dut.miq_count_w !== 0) ||
          (dut.miq1_count_w !== 0) ||
          (dut.mem_terminal_ingress_valid_w[10] !== 1'b0) ||
          (dut.mem_terminal_ingress_valid_w[11] !== 1'b0) ||
          (mem_req_valid !== 1'b0) ||
          (mem1_req_valid !== 1'b0))
        v11l_oracle_fail("flush-cancel-next-cycle");
      terminal_wait = 0;
      while (((dut.mem_owner_live_mask_w[V11L_TOKEN0] === 1'b1) ||
              (dut.mem_owner_live_mask_w[V11L_TOKEN1] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[V11L_TOKEN0] === 1'b1) ||
              (dut.mem_terminal_pending_mask_w[V11L_TOKEN1] === 1'b1)) &&
             (terminal_wait < 8)) begin
        `TB_TICK(clk);
        #1;
        terminal_wait = terminal_wait + 1;
      end
      if ((dut.mem_owner_live_mask_w[V11L_TOKEN0] !== 1'b0) ||
          (dut.mem_owner_live_mask_w[V11L_TOKEN1] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[V11L_TOKEN0] !== 1'b0) ||
          (dut.mem_terminal_pending_mask_w[V11L_TOKEN1] !== 1'b0))
        v11l_oracle_fail("flush-cancel-terminal-death");
      $display("[V11L-FLUSH-CANCEL-LANE10-EXACT][PASS] token=%0d",
               V11L_TOKEN0);
      $display("[V11L-FLUSH-CANCEL-LANE11-EXACT][PASS] token=%0d",
               V11L_TOKEN1);
      $display("[V11L-RETRY-HOLDER-MATRIX][PASS] capture=2 hold=2 c0=2 transfer=2 response=2 cancel=2");
      reset_dut();
    end
  endtask
`endif

  task automatic seed_v8t_retry1_from_unfilled_older_store;
    input load_is_fp;
    output [PRODUCER_ID_W-1:0] load_pid;
    output [4:0] load_token;
    output [1:0] load_epoch;
    output [`XLEN-1:0] load_tval;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      // The older store allocates an SQ entry but has not returned its probe
      // PA.  The younger load uses the other request bank and therefore can
      // reach its bridge; its final-PA query must replay on that unfilled
      // older entry.
      if (!load_is_fp) begin
        set_dispatch0(64'h0000_0000_8000_c680,
                      make_store_ctrl(`MEM_SIZE_DWORD),
                      5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0a00);
        set_dispatch1(64'h0000_0000_8000_c684,
                      make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                      5'd0, 5'd0, 5'd15, 64'h0000_0000_0000_0a08);
        #1;
        tb_check1("V8T retry seed dispatch0 ready", dispatch0_ready, 1'b1);
        tb_check1("V8T retry seed dispatch1 ready", dispatch1_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        `TB_TICK(clk);
        #1;
        tb_check1("V8T retry seed bank0 store probe", mem_req_valid, 1'b1);
        tb_check1("V8T retry seed bank0 semantic write", mem_req_write, 1'b1);
        tb_check1("V8T retry seed bank0 probe flag", mem_req_probe, 1'b1);
        tb_check1("V8T retry seed bank1 load", mem1_req_valid, 1'b1);
        tb_check1("V8T retry seed bank1 is read", mem1_req_write, 1'b0);
        tb_check64("V8T retry seed load VA", mem1_req_addr,
                   64'h0000_0000_0000_0a08);
        mem_req_ready = 1'b1;
        mem1_req_ready = 1'b1;
        #1;
        tb_check1("V8T retry seed store fires", dut.mem_req_fire_any_w,
                  1'b1);
        tb_check1("V8T retry seed load fires", dut.mem1_req_fire_any_w,
                  1'b1);
        `TB_TICK(clk);
        mem_req_ready = 1'b0;
        mem1_req_ready = 1'b0;
      end else begin
        // Dispatch the older store first and let its probe enter bank0 MIQ;
        // then a lane0 FP load can allocate its FPR destination and use bank1
        // while the SQ entry remains unfilled.
        set_dispatch0(64'h0000_0000_8000_c680,
                      make_store_ctrl(`MEM_SIZE_DWORD),
                      5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0a00);
        #1;
        tb_check1("V8T FP retry seed store dispatch ready",
                  dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        `TB_TICK(clk);
        #1;
        tb_check1("V8T FP retry seed store probe", mem_req_valid, 1'b1);
        mem_req_ready = 1'b1;
        `TB_TICK(clk);
        mem_req_ready = 1'b0;

        set_dispatch0(64'h0000_0000_8000_c684,
                      make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                      5'd0, 5'd0, 5'd15, 64'h0000_0000_0000_0a08);
        dispatch0_inst = {12'd0, 5'd0, `FUNCT3_LD, 5'd15,
                          `OPCODE_LOAD_FP};
        dispatch0_is_fp = 1'b1;
        dispatch0_fp_load = 1'b1;
        dispatch0_fp_double = 1'b1;
        #1;
        tb_check1("V8T FP retry seed load dispatch ready",
                  dispatch0_ready, 1'b1);
        `TB_TICK(clk);
        clear_dispatch();
        `TB_TICK(clk);
        #1;
        tb_check1("V8T FP retry seed bank1 load", mem1_req_valid, 1'b1);
        tb_check1("V8T FP retry seed bank1 is read", mem1_req_write, 1'b0);
        mem1_req_ready = 1'b1;
        #1;
        tb_check1("V8T FP retry seed load fires",
                  dut.mem1_req_fire_any_w, 1'b1);
        `TB_TICK(clk);
        mem1_req_ready = 1'b0;
      end
      #1;
      tb_check32("V8T retry seed bank0 MIQ resident", dut.miq_count_w, 32'd1);
      tb_check32("V8T retry seed bank1 MIQ resident", dut.miq1_count_w, 32'd1);
      tb_check32("V8T retry seed older SQ unfilled", dut.sq_count_w, 32'd1);
      load_pid = dut.mem1_completion_producer_id_w;
      load_token = mem1_expected_owner_token;
      load_epoch = mem1_expected_mmu_epoch;
      load_tval = mem1_expected_fault_tval;

      mem1_sq_query_valid = 1'b1;
      mem1_sq_query_owner_kind = mem1_expected_owner_kind;
      mem1_sq_query_owner_token = load_token;
      mem1_sq_query_mmu_epoch = load_epoch;
      mem1_sq_query_paddr = 64'h0000_0000_a000_0a08;
      mem1_sq_query_attr_valid = 1'b1;
      mem1_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem1_sq_query_wstrb = 8'hff;
`ifdef V9R_SQ_RETRY_C0_FOCUSED
      force dut.control_full_flush_barrier_w = 1'b1;
      #1;
      tb_check1("V9R bank1 C0 keeps exact SQ query",
                dut.mem1_sq_query_exact_w, 1'b1);
      tb_check1("V9R bank1 C0 keeps replay decision",
                mem1_sq_query_replay, 1'b1);
      tb_check1("V9R bank1 C0 withholds retry credit",
                mem1_sq_query_retry_ready, 1'b0);
      tb_check1("V9R bank1 C0 forbids retry capture",
                dut.mem_sq_retry1_capture_w, 1'b0);
      tb_check32("V9R bank1 C0 keeps MIQ owner resident",
                 dut.miq1_count_w, 32'd1);
      tb_check1("V9R bank1 C0 keeps retry holder empty",
                dut.mem_retry1_valid_q, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("V9R bank1 repeated C0 keeps MIQ owner resident",
                 dut.miq1_count_w, 32'd1);
      tb_check1("V9R bank1 repeated C0 keeps retry holder empty",
                dut.mem_retry1_valid_q, 1'b0);
      release dut.control_full_flush_barrier_w;
`endif
      #1;
      tb_check1("V8T retry query exact", dut.mem1_sq_query_exact_w, 1'b1);
      tb_check1("V8T retry query replays", mem1_sq_query_replay, 1'b1);
      tb_check1("V8T retry query does not allow", mem1_sq_query_allow, 1'b0);
      tb_check1("V8T retry query does not forward", mem1_sq_query_forward, 1'b0);
      tb_check1("V8T retry query has holder credit",
                mem1_sq_query_retry_ready, 1'b1);
      tb_check1("V8T retry query captures atomically",
                dut.mem_sq_retry1_capture_w, 1'b1);
      tb_check1("V8T retry capture is not a terminal",
                dut.mem_terminal_ingress_mask_w[load_token], 1'b0);
      `TB_TICK(clk);
      mem1_sq_query_valid = 1'b0;
      mem1_sq_query_attr_valid = 1'b0;
      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
      #1;
      tb_check1("V8T retry holder becomes resident", dut.mem_retry1_valid_q,
                1'b1);
      tb_check32("V8T retry capture exact token",
                 {27'b0, dut.mem_retry1_owner_token_q},
                 {27'b0, load_token});
      tb_check1("V8T retry capture exact full PID",
                dut.mem_retry1_producer_id_q == load_pid, 1'b1);
      tb_check1("V8T retry capture preserves destination domain",
                dut.mem_retry1_pdest_fp_q, load_is_fp);
      tb_check32("V8T retry capture pops bank1 MIQ",
                 dut.miq1_count_w, 32'd0);
      tb_check1("V8T retry capture keeps owner live",
                dut.mem_owner_live_mask_w[load_token], 1'b1);
    end
  endtask

  task automatic seed_v8t_retry0_from_unfilled_older_store;
    output [PRODUCER_ID_W-1:0] load_pid;
    output [4:0] load_token;
    output [1:0] load_epoch;
    output [`XLEN-1:0] load_tval;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      // Bank0 mirror of the bank1 retry seed.  The older bank1 store remains
      // an unfilled SQ entry while the younger bank0 load reaches final PA.
      set_dispatch0(64'h0000_0000_8000_c600,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0a08);
      set_dispatch1(64'h0000_0000_8000_c604,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd14, 64'h0000_0000_0000_0a00);
      #1;
      tb_check1("V8T retry0 seed dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8T retry0 seed dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8T retry0 seed bank1 store probe", mem1_req_valid, 1'b1);
      tb_check1("V8T retry0 seed bank1 semantic write", mem1_req_write, 1'b1);
      tb_check1("V8T retry0 seed bank1 probe flag", mem1_req_probe, 1'b1);
      tb_check1("V8T retry0 seed bank0 load", mem_req_valid, 1'b1);
      tb_check1("V8T retry0 seed bank0 is read", mem_req_write, 1'b0);
      tb_check64("V8T retry0 seed load VA", mem_req_addr,
                 64'h0000_0000_0000_0a00);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8T retry0 seed load fires", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8T retry0 seed store fires", dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      tb_check32("V8T retry0 seed bank0 MIQ resident", dut.miq_count_w,
                 32'd1);
      tb_check32("V8T retry0 seed bank1 MIQ resident", dut.miq1_count_w,
                 32'd1);
      tb_check32("V8T retry0 seed older SQ unfilled", dut.sq_count_w,
                 32'd1);
      load_pid = dut.mem_completion_producer_id_w;
      load_token = mem_expected_owner_token;
      load_epoch = mem_expected_mmu_epoch;
      load_tval = mem_expected_fault_tval;

      mem_sq_query_valid = 1'b1;
      mem_sq_query_owner_kind = mem_expected_owner_kind;
      mem_sq_query_owner_token = load_token;
      mem_sq_query_mmu_epoch = load_epoch;
      mem_sq_query_paddr = 64'h0000_0000_a000_0a00;
      mem_sq_query_attr_valid = 1'b1;
      mem_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem_sq_query_wstrb = 8'hff;
`ifdef V9R_SQ_RETRY_C0_FOCUSED
      force dut.control_full_flush_barrier_w = 1'b1;
      #1;
      tb_check1("V9R bank0 C0 keeps exact SQ query",
                dut.mem_sq_query_exact_w, 1'b1);
      tb_check1("V9R bank0 C0 keeps replay decision",
                mem_sq_query_replay, 1'b1);
      tb_check1("V9R bank0 C0 withholds retry credit",
                mem_sq_query_retry_ready, 1'b0);
      tb_check1("V9R bank0 C0 forbids retry capture",
                dut.mem_sq_retry0_capture_w, 1'b0);
      tb_check32("V9R bank0 C0 keeps MIQ owner resident",
                 dut.miq_count_w, 32'd1);
      tb_check1("V9R bank0 C0 keeps retry holder empty",
                dut.mem_retry0_valid_q, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check32("V9R bank0 repeated C0 keeps MIQ owner resident",
                 dut.miq_count_w, 32'd1);
      tb_check1("V9R bank0 repeated C0 keeps retry holder empty",
                dut.mem_retry0_valid_q, 1'b0);
      release dut.control_full_flush_barrier_w;
`endif
      #1;
      tb_check1("V8T retry0 query exact", dut.mem_sq_query_exact_w, 1'b1);
      tb_check1("V8T retry0 query replays", mem_sq_query_replay, 1'b1);
      tb_check1("V8T retry0 query does not allow", mem_sq_query_allow, 1'b0);
      tb_check1("V8T retry0 query does not forward", mem_sq_query_forward,
                1'b0);
      tb_check1("V8T retry0 query has holder credit",
                mem_sq_query_retry_ready, 1'b1);
      tb_check1("V8T retry0 query captures atomically",
                dut.mem_sq_retry0_capture_w, 1'b1);
      tb_check1("V8T retry0 capture is not a terminal",
                dut.mem_terminal_ingress_mask_w[load_token], 1'b0);
      `TB_TICK(clk);
      mem_sq_query_valid = 1'b0;
      mem_sq_query_attr_valid = 1'b0;
      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = {`STRB_W{1'b0}};
      #1;
      tb_check1("V8T retry0 holder becomes resident", dut.mem_retry0_valid_q,
                1'b1);
      tb_check32("V8T retry0 capture exact token",
                 {27'b0, dut.mem_retry0_owner_token_q},
                 {27'b0, load_token});
      tb_check1("V8T retry0 capture exact full PID",
                dut.mem_retry0_producer_id_q == load_pid, 1'b1);
      tb_check32("V8T retry0 capture pops bank0 MIQ", dut.miq_count_w,
                 32'd0);
      tb_check1("V8T retry0 capture keeps owner live",
                dut.mem_owner_live_mask_w[load_token], 1'b1);
    end
  endtask

  // V9R natural C0 proof.  A translated page-end load completes as the real
  // exception ROB head while commit is held.  Younger store/load owners then
  // establish an exact bank1 replay query.  Releasing commit readiness must
  // expose the ROB-derived TRAP barrier in the same combinational cycle and
  // keep the query owner in MIQ instead of transferring it to retry1.
  task automatic run_v9r_natural_trap_retry_barrier;
    reg [4:0] load_token;
    reg [1:0] load_epoch;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_translate_active = 1'b1;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      set_dispatch0(64'h0000_0000_8000_c740,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd26, 64'h0000_0000_4000_1ffc);
      #1;
      tb_check1("V9R natural trap head dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V9R natural trap head reaches memory reservation",
                dut.mem_issue_res_capture_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V9R natural trap head is local exception",
                dut.issue0_mem_exception_w, 1'b1);
      tb_check1("V9R natural trap head selects local EX0",
                dut.ex0_up_from_mem_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V9R natural trap head reaches formal WB",
                dut.ex0_wb_valid_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V9R natural trap waits while commit held",
                commit0_valid, 1'b0);
      tb_check1("V9R natural trap has no premature C0 barrier",
                control_full_flush_barrier, 1'b0);

      set_dispatch0(64'h0000_0000_8000_c744,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0a00);
      set_dispatch1(64'h0000_0000_8000_c748,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd27, 64'h0000_0000_0000_0a08);
      #1;
      tb_check1("V9R natural younger store dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("V9R natural younger load dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V9R natural younger bank0 store probe",
                mem_req_valid && mem_req_write && mem_req_probe, 1'b1);
      tb_check1("V9R natural younger bank1 load request",
                mem1_req_valid && !mem1_req_write && !mem1_req_probe, 1'b1);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      tb_check32("V9R natural bank1 load resident in MIQ",
                 dut.miq1_count_w, 32'd1);
      tb_check32("V9R natural older store resident in SQ",
                 dut.sq_count_w, 32'd1);
      load_token = mem1_expected_owner_token;
      load_epoch = mem1_expected_mmu_epoch;

      mem1_sq_query_valid = 1'b1;
      mem1_sq_query_owner_kind = mem1_expected_owner_kind;
      mem1_sq_query_owner_token = load_token;
      mem1_sq_query_mmu_epoch = load_epoch;
      mem1_sq_query_paddr = 64'h0000_0000_a000_0a08;
      mem1_sq_query_attr_valid = 1'b1;
      mem1_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem1_sq_query_wstrb = 8'hff;
      #1;
      tb_check1("V9R natural replay query exact before commit release",
                dut.mem1_sq_query_exact_w, 1'b1);
      tb_check1("V9R natural replay decision before commit release",
                mem1_sq_query_replay, 1'b1);
      tb_check1("V9R natural retry credit open before C0",
                mem1_sq_query_retry_ready, 1'b1);

      commit_ready = 1'b1;
      #1;
      tb_check1("V9R natural ROB head raises C0 barrier",
                control_full_flush_barrier, 1'b1);
      tb_check32("V9R natural C0 reason is TRAP",
                 {{(32-`REDIR_REASON_W){1'b0}},
                  control_full_flush_reason},
                 {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_TRAP});
      tb_check1("V9R natural trap commit packet is visible",
                commit0_valid && commit0_exception, 1'b1);
      tb_check1("V9R natural C0 withholds retry credit",
                mem1_sq_query_retry_ready, 1'b0);
      tb_check1("V9R natural C0 forbids retry capture",
                dut.mem_sq_retry1_capture_w, 1'b0);
      tb_check32("V9R natural C0 keeps MIQ owner resident",
                 dut.miq1_count_w, 32'd1);
      tb_check1("V9R natural C0 keeps retry holder empty",
                dut.mem_retry1_valid_q, 1'b0);
      `TB_TICK(clk);
      mem1_sq_query_valid = 1'b0;
      mem1_sq_query_attr_valid = 1'b0;
      mem1_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem1_sq_query_wstrb = {`STRB_W{1'b0}};
      commit_ready = 1'b0;
      #1;
      tb_check1("V9R natural C0 edge leaves retry holder empty",
                dut.mem_retry1_valid_q, 1'b0);
      tb_check32("V9R natural C0 edge preserves younger MIQ owner",
                 dut.miq1_count_w, 32'd1);
      reset_dut();
      $display("[V9R-SQ-RETRY-NATURAL-TRAP] rob_head=1 bank1=1 PASS");
    end
  endtask

  task automatic run_v9r_sq_retry_c0_handoff;
    reg [PRODUCER_ID_W-1:0] load_pid;
    reg [4:0] load_token;
    reg [1:0] load_epoch;
    reg [`XLEN-1:0] load_tval;
    begin
      seed_v8t_retry0_from_unfilled_older_store(
          load_pid, load_token, load_epoch, load_tval);
      seed_v8t_retry1_from_unfilled_older_store(
          1'b0, load_pid, load_token, load_epoch, load_tval);
      run_v9r_natural_trap_retry_barrier();
      $display("[V9R-SQ-RETRY-C0-HANDOFF-PASS] banks=2 forced=2 natural_trap=1 PASS");
    end
  endtask

  // V9P replay-capacity admission proof.  In each bank mirror an older store
  // owns a real, nonterminal SQ entry while load A already occupies the same
  // bank's bridge query residency.  A younger same-bank load B must remain in
  // its issue reservation until either the older SQ relation or A's
  // active/station residency disappears.  This is intentionally narrower
  // than the old F3 fence: SQ-empty current/next load handoff remains legal.
  task automatic run_v9p_replay_capacity_admission;
    reg [4:0] active_token;
    begin
      // Bank0: older bank1 store, active bank0 load A, then bank0 load B.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c720,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0d08);
      set_dispatch1(64'h0000_0000_8000_c724,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd22, 64'h0000_0000_0000_0d00);
      #1;
      tb_check1("V9P bank0 seed store dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("V9P bank0 seed load A dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V9P bank0 seed presents bank1 store probe",
                mem1_req_valid && mem1_req_write && mem1_req_probe, 1'b1);
      tb_check1("V9P bank0 seed presents bank0 load A",
                mem_req_valid && !mem_req_write && !mem_req_probe, 1'b1);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V9P bank0 load A request fires",
                dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V9P bank0 older store probe fires",
                dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      tb_check32("V9P bank0 load A owns MIQ", dut.miq_count_w, 32'd1);
      tb_check32("V9P bank0 older store owns SQ", dut.sq_count_w, 32'd1);
      active_token = dut.miq_head_owner_token_w;

      mem_owner_query_valid = 1'b1;
      mem_owner_query_token = active_token;
      set_dispatch0(64'h0000_0000_8000_c728,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd23, 64'h0000_0000_0000_0d10);
      #1;
      tb_check1("V9P bank0 load B dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V9P bank0 load B reaches ordinary candidate",
                dut.issue0_dual_ordinary_candidate_w, 1'b1);
      tb_check1("V9P bank0 load B sees older nonterminal SQ owner",
                dut.issue0_sq_block_r, 1'b1);
      tb_check1("V9P bank0 active query identifies load A",
                dut.mem_bridge_active_load_w, 1'b1);
      tb_check1("V9P bank0 retry holder remains empty",
                dut.mem_retry0_valid_q, 1'b0);
      tb_check1("V9P bank0 active residency blocks load B admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);
      // Hold the exact relation over a clock edge so the RTL assertion is
      // non-vacuous for the compile-success fence-open mutation.
      `TB_TICK(clk);
      #1;
      tb_check1("V9P bank0 blocked load B remains a candidate",
                dut.issue0_dual_ordinary_candidate_w, 1'b1);
      tb_check1("V9P bank0 active fence holds across one cycle",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);

      mem_owner_query_valid = 1'b0;
      mem_station_query_valid = 1'b1;
      mem_station_query_token = active_token;
      #1;
      tb_check1("V9P bank0 station query identifies load A",
                dut.mem_bridge_station_load_w, 1'b1);
      tb_check1("V9P bank0 station residency blocks load B admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);
      mem_station_query_valid = 1'b0;

      // Bank1 mirror: older bank0 store, active bank1 load A, then load B.
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c730,
                    make_store_ctrl(`MEM_SIZE_DWORD),
                    5'd0, 5'd0, 5'd0, 64'h0000_0000_0000_0e00);
      set_dispatch1(64'h0000_0000_8000_c734,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd24, 64'h0000_0000_0000_0e08);
      #1;
      tb_check1("V9P bank1 seed store dispatch ready",
                dispatch0_ready, 1'b1);
      tb_check1("V9P bank1 seed load A dispatch ready",
                dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V9P bank1 seed presents bank0 store probe",
                mem_req_valid && mem_req_write && mem_req_probe, 1'b1);
      tb_check1("V9P bank1 seed presents bank1 load A",
                mem1_req_valid && !mem1_req_write && !mem1_req_probe, 1'b1);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V9P bank1 older store probe fires",
                dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V9P bank1 load A request fires",
                dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      tb_check32("V9P bank1 load A owns MIQ", dut.miq1_count_w, 32'd1);
      tb_check32("V9P bank1 older store owns SQ", dut.sq_count_w, 32'd1);
      active_token = dut.miq1_head_owner_token_w;

      mem1_owner_query_valid = 1'b1;
      mem1_owner_query_token = active_token;
      set_dispatch0(64'h0000_0000_8000_c738,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd25, 64'h0000_0000_0000_0e18);
      #1;
      tb_check1("V9P bank1 load B dispatch ready",
                dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V9P bank1 load B reaches ordinary candidate",
                dut.issue0_dual_ordinary_candidate_w, 1'b1);
      tb_check1("V9P bank1 load B sees older nonterminal SQ owner",
                dut.issue0_sq_block_r, 1'b1);
      tb_check1("V9P bank1 active query identifies load A",
                dut.mem1_bridge_active_load_w, 1'b1);
      tb_check1("V9P bank1 retry holder remains empty",
                dut.mem_retry1_valid_q, 1'b0);
      tb_check1("V9P bank1 active residency blocks load B admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V9P bank1 blocked load B remains a candidate",
                dut.issue0_dual_ordinary_candidate_w, 1'b1);
      tb_check1("V9P bank1 active fence holds across one cycle",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);

      mem1_owner_query_valid = 1'b0;
      mem1_station_query_valid = 1'b1;
      mem1_station_query_token = active_token;
      #1;
      tb_check1("V9P bank1 station query identifies load A",
                dut.mem1_bridge_station_load_w, 1'b1);
      tb_check1("V9P bank1 station residency blocks load B admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);
      mem1_station_query_valid = 1'b0;
      reset_dut();
      $display("[V9P-REPLAY-CAPACITY-ADMISSION] banks=2 active=2 station=2 older_sq=4 PASS");
    end
  endtask

  // v8u/F4 backend-local current/next identity proof.  Two real LOAD owners
  // are allocated, issued and pushed into bank0 MIQ.  A station-sourced query
  // for B is fail-closed without A response, remains fail-closed when A is
  // effective-killed, and becomes the sole SQ allow when A's registered
  // response identity is exact.  Response READY is intentionally excluded
  // from this side-effect-free comparison; only the later exact response fire
  // may pop A while B remains live and becomes current.
  task automatic run_v8u_current_pop_next_head_query;
    reg [4:0] a_token;
    reg [4:0] b_token;
    integer wait_i;
    begin
      reset_dut();
      commit_ready = 1'b0;
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      set_dispatch0(64'h0000_0000_8000_c700,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd20, 64'h0000_0000_0000_0b00);
      #1;
      tb_check1("V8U A dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8U A bank0 request valid", mem_req_valid, 1'b1);
      tb_check1("V8U A avoids bank1", mem1_req_valid, 1'b0);
      mem_req_ready = 1'b1;
      `TB_TICK(clk);
      mem_req_ready = 1'b0;

      set_dispatch0(64'h0000_0000_8000_c704,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd21, 64'h0000_0000_0000_0b10);
      #1;
      tb_check1("V8U B dispatch ready", dispatch0_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8U B bank0 request valid", mem_req_valid, 1'b1);
      tb_check1("V8U B avoids bank1", mem1_req_valid, 1'b0);
      mem_req_ready = 1'b1;
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;

      tb_check32("V8U bank0 has A/B", dut.miq_count_w, 32'd2);
      tb_check1("V8U bank0 next valid", dut.miq_next_head_valid_w, 1'b1);
      a_token = dut.miq_head_owner_token_w;
      b_token = dut.miq_next_head_owner_token_w;
      tb_check1("V8U A/B tokens distinct", a_token != b_token, 1'b1);
      tb_check32("V8U B next kind LOAD", {30'b0, dut.miq_next_head_kind_w},
                 32'd0);

      // A must already carry a retire-resident final-PA disposition before
      // the held/exact response probes below can participate in the response
      // allocator.  B is ordered later by its real next-head SQ query.
      v8v_record_load_head_order(
          "V8U current A", 1'b1, 64'h0000_0000_a000_0b00,
          1'b0, {`XLEN{1'b0}});

      mem_station_query_valid = 1'b1;
      mem_station_query_token = b_token;
      mem_sq_query_valid = 1'b1;
      mem_sq_query_owner_kind = dut.miq_next_head_owner_kind_w;
      mem_sq_query_owner_token = b_token;
      mem_sq_query_mmu_epoch = dut.miq_next_head_mmu_epoch_w;
      mem_sq_query_paddr = 64'h0000_0000_a000_0b10;
      mem_sq_query_attr_valid = 1'b1;
      mem_sq_query_class = `OOO_MEM_CLASS_CACHED;
      mem_sq_query_wstrb = 8'hff;
      #1;
      tb_check1("V8U station source recognized",
                dut.mem_sq_query_station_source_w, 1'b1);
      tb_check1("V8U no A response means no next exact",
                dut.mem_sq_query_next_miq_exact_w, 1'b0);
      tb_check1("V8U no A response replays B", mem_sq_query_replay, 1'b1);
      tb_check1("V8U lookahead never receives retry credit",
                mem_sq_query_retry_ready, 1'b0);
      tb_check32("V8U no A response keeps two MIQ entries",
                 dut.miq_count_w, 32'd2);

      // Even an otherwise exact A transport cannot authorize B when current A
      // is effective-killed.  Do not clock this probe; the following positive
      // edge must still own A.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1111_0000_0000_0001;
      force dut.miq_head_effective_killed_w = 1'b1;
      #1;
      tb_check1("V8U killed A blocks current exact fire",
                dut.mem_current_rsp_exact_fire_w, 1'b0);
      tb_check1("V8U killed A keeps B replay", mem_sq_query_replay, 1'b1);
      tb_check1("V8U killed A does not enable retry",
                mem_sq_query_retry_ready, 1'b0);
      release dut.miq_head_effective_killed_w;
      mem_rsp_valid = 1'b0;
      #1;

      // Hold A's response credit low.  The exact Q identity may authorize the
      // side-effect-free SQ comparison for B, but neither A pop nor any retry
      // capture is permitted until the response handshake occurs.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h1a1a_0000_0000_0001;
      force dut.mem_rsp_ready_o = 1'b0;
      #1;
      tb_check1("V8U held A response exact candidate",
                dut.mem_current_rsp_exact_candidate_w, 1'b1);
      tb_check1("V8U held A response is not a fire",
                dut.mem_current_rsp_exact_fire_w, 1'b0);
      tb_check1("V8U held response keeps B next-head exact",
                dut.mem_sq_query_next_miq_exact_w, 1'b1);
      tb_check1("V8U held response permits read-only SQ allow",
                mem_sq_query_allow, 1'b1);
      tb_check1("V8U held response performs no MIQ pop",
                dut.miq_queue_pop_valid_w, 1'b0);
      tb_check1("V8U held station query receives no retry credit",
                mem_sq_query_retry_ready, 1'b0);
      release dut.mem_rsp_ready_o;
      mem_rsp_valid = 1'b0;
      #1;

      // Exact A response and B next query share one cycle.  B uses the normal
      // StoreQueue CAM, returns allow, and cannot capture the retry holder.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h2222_0000_0000_0002;
      #1;
      tb_check1("V8U A response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8U A exact response fire",
                dut.mem_current_rsp_exact_fire_w, 1'b1);
      tb_check1("V8U B exact next-head match",
                dut.mem_sq_query_next_miq_exact_w, 1'b1);
      tb_check1("V8U B full exact query", dut.mem_sq_query_exact_w, 1'b1);
      tb_check1("V8U B SQ allow", mem_sq_query_allow, 1'b1);
      tb_check1("V8U B no forward", mem_sq_query_forward, 1'b0);
      tb_check1("V8U B no replay", mem_sq_query_replay, 1'b0);
      tb_check1("V8U B lookahead retry credit remains zero",
                mem_sq_query_retry_ready, 1'b0);
      tb_check1("V8U response owns sole queue pop",
                dut.miq_queue_pop_valid_w && !dut.mem_sq_retry0_capture_w,
                1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_sq_query_valid = 1'b0;
      mem_sq_query_attr_valid = 1'b0;
      mem_sq_query_class = `OOO_MEM_CLASS_RSVD;
      mem_sq_query_wstrb = {`STRB_W{1'b0}};
      mem_station_query_valid = 1'b0;
      #1;
      tb_check32("V8U one pop leaves B", dut.miq_count_w, 32'd1);
      tb_check32("V8U B becomes current",
                 {27'b0, dut.miq_head_owner_token_w}, {27'b0, b_token});
      tb_check1("V8U B tracker remains live",
                dut.mem_owner_live_mask_w[b_token], 1'b1);

      // Drain B and all bookkeeping so this focused task has no ghost owner.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h3333_0000_0000_0003;
      #1;
      tb_check1("V8U B response ready", mem_rsp_ready, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      commit_ready = 1'b1;
      #1;
      wait_i = 0;
      while (((rob_count != 0) || (dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 16)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8U A/B ROB drains", rob_count, 32'd0);
      tb_check32("V8U A/B owners drain", dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8U A/B terminal collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      $display("[V8U-F4-BACKEND-NEXT] no-pop/killed-current fail-closed + exact A-pop/B-allow PASS");
    end
  endtask

  task automatic run_v8t_final_pa_retry_lifecycle;
    reg [PRODUCER_ID_W-1:0] load_pid;
    reg [4:0] load_token;
    reg [1:0] load_epoch;
    reg [`XLEN-1:0] load_tval;
    integer wait_i;
    begin
      // Bank0 mirror: exact replay capture, backpressure hold, same-token
      // reissue/MIQ push, and cancellation-dominant ready race.
      seed_v8t_retry0_from_unfilled_older_store(
          load_pid, load_token, load_epoch, load_tval);
      // An edge-old F4 state can already contain a distinct younger load when
      // the active owner transfers into retry0.  This check proves only
      // identity disjointness.  V9P separately prevents a new replay-capable
      // load with an older SQ owner from creating this capacity state.
      mem_station_query_valid = 1'b1;
      mem_station_query_token = load_token ^ 5'b10000;
      force dut.mem_bridge_station_load_w = 1'b1;
      `TB_TICK(clk);
      release dut.mem_bridge_station_load_w;
      mem_station_query_valid = 1'b0;
      mem_station_query_token = 5'b0;
      #1;
      tb_check1("V9L distinct station load may coexist with retry0",
                dut.mem_retry0_valid_q, 1'b1);
      tb_check1("V9L retry0 still fences new bank0 load",
                dut.mem_bank0_load_admission_block_w, 1'b1);
      $display("[V9L-RETRY-DISTINCT-RESIDENCY] retry0 + distinct station load PASS");
      #1;
      tb_check1("V8T retry0 request valid under backpressure",
                mem_req_valid, 1'b1);
      tb_check1("V8T retry0 request selected", dut.grant_retry0_w, 1'b1);
      tb_check1("V8T retry0 request is ordinary load", mem_req_write, 1'b0);
      tb_check1("V8T retry0 request is not probe", mem_req_probe, 1'b0);
      tb_check32("V8T retry0 request preserves token",
                 {27'b0, mem_req_owner_token}, {27'b0, load_token});
      tb_check1("V8T retry0 holder blocks a second bank0 load",
                dut.mem_bank0_load_admission_block_w, 1'b1);
      force dut.issue0_dual_ordinary_candidate_w = 1'b1;
      force dut.issue0_is_load_w = 1'b1;
      force dut.issue0_is_amo_w = 1'b0;
      force dut.issue0_dual_bank1_w = 1'b0;
      force dut.issue0_dual_bank_slot_open_w = 1'b1;
      #1;
      tb_check1("V8T retry0 holder fence blocks load admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);
      release dut.issue0_dual_ordinary_candidate_w;
      release dut.issue0_is_load_w;
      release dut.issue0_is_amo_w;
      release dut.issue0_dual_bank1_w;
      release dut.issue0_dual_bank_slot_open_w;
      `TB_TICK(clk);
      #1;
      tb_check1("V8T retry0 holder remains under backpressure",
                dut.mem_retry0_valid_q, 1'b1);
      tb_check32("V8T retry0 bank0 MIQ remains empty before fire",
                 dut.miq_count_w, 32'd0);

      mem_req_ready = 1'b1;
      #1;
      tb_check1("V8T retry0 exact request fires",
                dut.mem_retry0_req_fire_w, 1'b1);
      tb_check1("V8T retry0 fire pushes LOAD", dut.push_retry0_w, 1'b1);
      `TB_TICK(clk);
      mem_req_ready = 1'b0;
      #1;
      tb_check1("V8T retry0 holder clears after fire",
                dut.mem_retry0_valid_q, 1'b0);
      tb_check32("V8T retry0 re-pushes one MIQ entry",
                 dut.miq_count_w, 32'd1);
      tb_check32("V8T retry0 re-push exact token",
                 {27'b0, dut.miq_head_owner_token_w},
                 {27'b0, load_token});
      tb_check1("V8T retry0 re-push exact full PID",
                dut.mem_completion_producer_id_w == load_pid, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8T retry0 re-push persists without response",
                 dut.miq_count_w, 32'd1);

      // Complete the older bank1 store probe at a nonalias physical address.
      // The load then repeats its original final-PA tuple, converting the LQ
      // disposition from replay to allow without changing transaction ID.
      mem1_rsp_valid = 1'b1;
      mem1_rsp_rdata = 64'h0000_0000_b000_0a08;
      #1;
      tb_check1("V8T retry0 older store response ready",
                mem1_rsp_ready, 1'b1);
      tb_check1("V8T retry0 older store fills SQ",
                dut.sq_fill1_valid_w, 1'b1);
      `TB_TICK(clk);
      mem1_rsp_valid = 1'b0;
      mem1_rsp_rdata = {`XLEN{1'b0}};
      v8v_record_load_head_order(
          "V8T retry0 release", 1'b1, 64'h0000_0000_a000_0a00,
          1'b0, {`XLEN{1'b0}});
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0bad_c0de_7654_3210;
      #1;
      tb_check1("V8T retry0 integer response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8T retry0 integer response stays out of FP sink",
                dut.mem_rsp_fp_load_w, 1'b0);
      tb_check1("V8T retry0 integer response has integer destination",
                dut.mem_rsp_int_pdest_w != {PHY_REG_ADDR_W{1'b0}}, 1'b1);
      tb_check1("V8T retry0 integer response reaches formal WB",
                dut.wb0_valid_w || dut.wb1_valid_w, 1'b1);
      tb_check1("V8T retry0 integer response emits no FP-load WB",
                dut.mem_fpld_wb_valid_w, 1'b0);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};

      seed_v8t_retry0_from_unfilled_older_store(
          load_pid, load_token, load_epoch, load_tval);
      mem_req_ready = 1'b1;
      flush = 1'b1;
      #1;
      tb_check1("V8T retry0 ready/cancel race recognizes cancel",
                dut.mem_retry0_cancel_w, 1'b1);
      tb_check1("V8T retry0 ready/cancel race blocks request fire",
                dut.mem_retry0_req_fire_w, 1'b0);
      tb_check1("V8T killed retry0 owns terminal lane10",
                dut.mem_terminal_ingress_valid_w[10], 1'b1);
      tb_check32("V8T killed retry0 terminal exact token",
                 {27'b0, dut.mem_terminal_ingress_token_w[10*5 +: 5]},
                 {27'b0, load_token});
      tb_check1("V8T killed retry0 terminal appears once in mask",
                dut.mem_terminal_ingress_mask_w[load_token], 1'b1);
      `TB_TICK(clk);
      flush = 1'b0;
      mem_req_ready = 1'b0;
      #1;
      tb_check1("V8T killed retry0 holder clears",
                dut.mem_retry0_valid_q, 1'b0);
      tb_check1("V8T killed retry0 lane is a pulse",
                dut.mem_terminal_ingress_valid_w[10], 1'b0);
      wait_i = 0;
      while (dut.mem_owner_live_mask_w[load_token] && (wait_i < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check1("V8T killed retry0 frees exact owner",
                dut.mem_owner_live_mask_w[load_token], 1'b0);

      // Capture -> bridge release -> exact same-token request/MIQ re-push.
      seed_v8t_retry1_from_unfilled_older_store(
          1'b0, load_pid, load_token, load_epoch, load_tval);
      // A real resident holder must fence a second load in the same bank.
      force dut.issue0_dual_ordinary_candidate_w = 1'b1;
      force dut.issue0_is_load_w = 1'b1;
      force dut.issue0_is_amo_w = 1'b0;
      force dut.issue0_dual_bank1_w = 1'b1;
      force dut.issue0_dual_bank_slot_open_w = 1'b1;
      #1;
      tb_check1("V8T retry1 holder is sole bank1 fence source",
                dut.mem_retry1_valid_q &&
                !dut.mem1_bridge_active_load_w &&
                !dut.mem1_bridge_station_load_w, 1'b1);
      tb_check1("V8T retry1 holder fence blocks load admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b0);
      release dut.issue0_dual_ordinary_candidate_w;
      release dut.issue0_is_load_w;
      release dut.issue0_is_amo_w;
      release dut.issue0_dual_bank1_w;
      release dut.issue0_dual_bank_slot_open_w;

      // Same-bank store/retry arbitration uses ROB distance from the live
      // head.  Older store wins; equal-age and younger stores cannot overtake
      // the retry owner.
      force dut.issue0_dual_base_selected_w = 1'b1;
      force dut.issue0_is_plain_store_w = 1'b1;
      force dut.issue0_dual_bank1_w = 1'b1;
      v8t_force_store_rob = dut.mem_retry1_rob_idx_q - 1'b1;
      force dut.mem_issue_res_rob_idx_q = v8t_force_store_rob;
      #1;
      tb_check1("V8T older bank1 store recognized",
                dut.mem_bank1_store_older_than_retry_w, 1'b1);
      tb_check1("V8T older bank1 store suppresses retry",
                dut.mem_retry1_selected_w, 1'b0);
      tb_check1("V8T older bank1 store remains selected",
                dut.issue0_dual_selected_w, 1'b1);
      release dut.mem_issue_res_rob_idx_q;
      v8t_force_store_rob = dut.mem_retry1_rob_idx_q;
      force dut.mem_issue_res_rob_idx_q = v8t_force_store_rob;
      #1;
      tb_check1("V8T equal-age bank1 store is not older",
                dut.mem_bank1_store_older_than_retry_w, 1'b0);
      tb_check1("V8T equal-age bank1 store yields to retry",
                dut.mem_retry1_selected_w, 1'b1);
      release dut.mem_issue_res_rob_idx_q;
      v8t_force_store_rob = dut.mem_retry1_rob_idx_q + 1'b1;
      force dut.mem_issue_res_rob_idx_q = v8t_force_store_rob;
      #1;
      tb_check1("V8T younger bank1 store is not older",
                dut.mem_bank1_store_older_than_retry_w, 1'b0);
      tb_check1("V8T younger bank1 store yields to retry",
                dut.mem_retry1_selected_w, 1'b1);
      release dut.mem_issue_res_rob_idx_q;
      release dut.issue0_dual_base_selected_w;
      release dut.issue0_is_plain_store_w;
      release dut.issue0_dual_bank1_w;
      #1;
      tb_check1("V8T retry request valid under backpressure",
                mem1_req_valid, 1'b1);
      tb_check1("V8T retry request selected", dut.grant_retry1_w, 1'b1);
      tb_check1("V8T retry request is ordinary load", mem1_req_write, 1'b0);
      tb_check1("V8T retry request is not probe", mem1_req_probe, 1'b0);
      tb_check1("V8T retry request preserves killability",
                mem1_req_nokill, 1'b0);
      tb_check64("V8T retry request preserves original address",
                 mem1_req_addr, 64'h0000_0000_0000_0a08);
      tb_check32("V8T retry request preserves token",
                 {27'b0, mem1_req_owner_token}, {27'b0, load_token});
      tb_check32("V8T retry request preserves epoch",
                 {30'b0, mem1_req_mmu_epoch}, {30'b0, load_epoch});
      tb_check64("V8T retry request preserves tval",
                 mem1_req_fault_tval, load_tval);
      tb_check1("V8T retry does not fire without bridge ready",
                dut.mem_retry1_req_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8T retry holder remains under backpressure",
                dut.mem_retry1_valid_q, 1'b1);
      tb_check32("V8T retry bank1 MIQ remains empty before fire",
                 dut.miq1_count_w, 32'd0);

      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8T retry exact request fires",
                dut.mem_retry1_req_fire_w, 1'b1);
      tb_check1("V8T retry fire pushes LOAD", dut.push_retry1_w, 1'b1);
      `TB_TICK(clk);
      mem1_req_ready = 1'b0;
      #1;
      tb_check1("V8T retry holder clears after fire",
                dut.mem_retry1_valid_q, 1'b0);
      tb_check32("V8T retry re-pushes one MIQ entry",
                 dut.miq1_count_w, 32'd1);
      tb_check1("V8T retry re-push keeps LOAD kind", dut.miq1_head_load_w,
                1'b1);
      tb_check32("V8T retry re-push exact token",
                 {27'b0, dut.miq1_head_owner_token_w},
                 {27'b0, load_token});
      tb_check1("V8T retry re-push exact full PID",
                dut.mem1_completion_producer_id_w == load_pid, 1'b1);
      tb_check1("V8T retry re-push remains nonterminal",
                dut.mem_terminal_ingress_mask_w[load_token], 1'b0);
      // One further edge exercises the next-Q MIQ residency assertion.
      `TB_TICK(clk);
      #1;
      tb_check32("V8T retry re-push persists without response",
                 dut.miq1_count_w, 32'd1);

      // F4 keeps active/station handoff open when the candidate has no older
      // SQ owner.  Force that candidate-side age fact explicitly here; V9P's
      // natural SQ-resident trajectory covers the blocked counterpart.
      mem1_owner_query_valid = 1'b1;
      mem1_owner_query_token = load_token;
      force dut.issue0_dual_ordinary_candidate_w = 1'b1;
      force dut.issue0_is_load_w = 1'b1;
      force dut.issue0_is_amo_w = 1'b0;
      force dut.issue0_dual_bank1_w = 1'b1;
      force dut.issue0_dual_bank_slot_open_w = 1'b1;
      force dut.issue0_sq_block_r = 1'b0;
      #1;
      tb_check1("V8T bridge-active source identifies live load",
                dut.mem1_bridge_active_load_w, 1'b1);
      tb_check1("V8U no-older-SQ active residency keeps F4 admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b1);
      mem1_owner_query_valid = 1'b0;
      release dut.issue0_dual_ordinary_candidate_w;
      release dut.issue0_is_load_w;
      release dut.issue0_is_amo_w;
      release dut.issue0_dual_bank1_w;
      release dut.issue0_dual_bank_slot_open_w;
      release dut.issue0_sq_block_r;

      mem1_station_query_valid = 1'b1;
      mem1_station_query_token = load_token;
      force dut.issue0_dual_ordinary_candidate_w = 1'b1;
      force dut.issue0_is_load_w = 1'b1;
      force dut.issue0_is_amo_w = 1'b0;
      force dut.issue0_dual_bank1_w = 1'b1;
      force dut.issue0_dual_bank_slot_open_w = 1'b1;
      force dut.issue0_sq_block_r = 1'b0;
      #1;
      tb_check1("V8T bridge-station source identifies live load",
                dut.mem1_bridge_station_load_w, 1'b1);
      tb_check1("V8U no-older-SQ station residency keeps F4 admission",
                dut.issue0_dual_ordinary_admitted_w, 1'b1);
      mem1_station_query_valid = 1'b0;
      release dut.issue0_dual_ordinary_candidate_w;
      release dut.issue0_is_load_w;
      release dut.issue0_is_amo_w;
      release dut.issue0_dual_bank1_w;
      release dut.issue0_dual_bank_slot_open_w;
      release dut.issue0_sq_block_r;

      // A second exact capture cancelled by global flush must emit exactly
      // the retry-holder terminal, never a request fire or architectural WB.
      seed_v8t_retry1_from_unfilled_older_store(
          1'b0, load_pid, load_token, load_epoch, load_tval);
      mem1_req_ready = 1'b1;
      flush = 1'b1;
      #1;
      tb_check1("V8T killed retry recognizes cancel",
                dut.mem_retry1_cancel_w, 1'b1);
      tb_check1("V8T killed retry blocks request fire",
                dut.mem_retry1_req_fire_w, 1'b0);
      tb_check1("V8T killed retry owns terminal lane11",
                dut.mem_terminal_ingress_valid_w[11], 1'b1);
      tb_check32("V8T killed retry terminal exact token",
                 {27'b0, dut.mem_terminal_ingress_token_w[11*5 +: 5]},
                 {27'b0, load_token});
      tb_check1("V8T killed retry terminal appears once in mask",
                dut.mem_terminal_ingress_mask_w[load_token], 1'b1);
      tb_check1("V8T killed retry has no WB0", dut.wb0_valid_w, 1'b0);
      tb_check1("V8T killed retry has no WB1", dut.wb1_valid_w, 1'b0);
      `TB_TICK(clk);
      flush = 1'b0;
      mem1_req_ready = 1'b0;
      #1;
      tb_check1("V8T killed retry holder clears",
                dut.mem_retry1_valid_q, 1'b0);
      tb_check1("V8T killed retry lane is a pulse",
                dut.mem_terminal_ingress_valid_w[11], 1'b0);
      tb_check32("V8T killed retry MIQ remains empty",
                 dut.miq1_count_w, 32'd0);
      wait_i = 0;
      while (dut.mem_owner_live_mask_w[load_token] && (wait_i < 8)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check1("V8T killed retry frees exact owner",
                dut.mem_owner_live_mask_w[load_token], 1'b0);
      tb_check1("V8T killed retry never commits", commit0_valid, 1'b0);

      // FP-load destination-domain metadata traverses the same retry holder
      // and reissue path, then selects only the FP load writeback sink.
      seed_v8t_retry1_from_unfilled_older_store(
          1'b1, load_pid, load_token, load_epoch, load_tval);
      tb_check1("V8T FP retry holder preserves FP destination",
                dut.mem_retry1_pdest_fp_q, 1'b1);
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8T FP retry request fires",
                dut.mem_retry1_req_fire_w, 1'b1);
      `TB_TICK(clk);
      mem1_req_ready = 1'b0;
      #1;
      tb_check1("V8T FP retry re-push preserves FP destination",
                dut.miq1_head_pdest_fp_w, 1'b1);

      // Resolve the older bank0 store probe at a nonalias PA, then repeat the
      // FP load's original final-PA metadata before accepting its response.
      mem_rsp_valid = 1'b1;
      mem_rsp_rdata = 64'h0000_0000_b000_0a00;
      #1;
      tb_check1("V8T FP retry older store response ready",
                mem_rsp_ready, 1'b1);
      tb_check1("V8T FP retry older store fills SQ",
                dut.sq_fill_valid_w, 1'b1);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem_rsp_rdata = {`XLEN{1'b0}};
      v8v_record_load_head_order(
          "V8T FP retry release", 1'b0, {`XLEN{1'b0}},
          1'b1, 64'h0000_0000_a000_0a08);
      mem1_rsp_valid = 1'b1;
      mem1_rsp_rdata = 64'hfeed_face_89ab_cdef;
      #1;
      tb_check1("V8T FP retry response ready", mem1_rsp_ready, 1'b1);
      tb_check1("V8T FP retry response classified FP",
                dut.mem1_rsp_fp_load_w, 1'b1);
      tb_check1("V8T FP retry response reaches FP-load WB",
                dut.mem1_fpld_wb_valid_w, 1'b1);
      tb_check32("V8T FP retry response has p0 integer destination",
                 {26'b0, dut.mem1_rsp_int_pdest_w}, 32'd0);
      tb_check1("V8T FP retry response emits FP wake",
                dut.fp_wake1_valid_w, 1'b1);
      `TB_TICK(clk);
      mem1_rsp_valid = 1'b0;
      mem1_rsp_rdata = {`XLEN{1'b0}};
      reset_dut();
      $display("[V8T-F3-BACKEND-RETRY] bank0/bank1 capture-hold-reissue-kill + age arbitration + retry fence/F4 real-capacity admission + int/FP sinks + ready/cancel races PASS");
    end
  endtask

  // v8u/F4 asymmetric consume boundary.  A/B map to the same physical bank,
  // so only A can consume on the first edge.  C/D are already resident behind
  // the two reservation Qs.  Partial consume must neither dequeue C/D nor
  // refill only one reservation; after B drains, the ordinary pair path may
  // capture C/D together.
  task automatic run_v8u_partial_consume_no_turnover;
    begin
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;

      set_dispatch0(64'h0000_0000_8000_cf00,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd24, 64'h0000_0000_0000_1000);
      set_dispatch1(64'h0000_0000_8000_cf04,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd25, 64'h0000_0000_0000_1020);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8U partial setup reservation0 valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V8U partial setup reservation1 valid",
                dut.mem_issue1_res_valid_q, 1'b1);

      set_dispatch0(64'h0000_0000_8000_cf08,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd26, 64'h0000_0000_0000_1040);
      set_dispatch1(64'h0000_0000_8000_cf0c,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd27, 64'h0000_0000_0000_1060);
      #1;
      tb_check1("V8U partial C dispatch ready", dispatch0_ready, 1'b1);
      tb_check1("V8U partial D dispatch ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check32("V8U partial C/D resident behind reservations",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("V8U partial pair peek valid",
                dut.iq_memory_pair_peek_valid_w, 1'b1);

      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8U partial only reservation0 consumes",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("V8U partial reservation1 does not consume",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      tb_check1("V8U partial consume forbids turnover",
                dut.mem_issue_pair_turnover_capture_w, 1'b0);
      tb_check1("V8U partial consume withholds IQ pop2 ready",
                dut.iq_memory_pair_peek_ready_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8U partial reservation0 drains",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("V8U partial reservation1 remains",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check32("V8U partial C/D remain resident",
                 {28'b0, issue_count}, 32'd2);

      tb_check1("V8U partial reservation1 consumes next",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      tb_check1("V8U singleton drain still forbids turnover",
                dut.mem_issue_pair_turnover_capture_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8U both old reservations drained",
                !dut.mem_issue_res_valid_q &&
                !dut.mem_issue1_res_valid_q, 1'b1);
      tb_check32("V8U C/D survive both partial edges",
                 {28'b0, issue_count}, 32'd2);
      tb_check1("V8U C/D return to ordinary pair selection",
                dut.iq_memory_pair_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8U C/D capture atomically after old pair drains",
                dut.mem_issue_res_valid_q &&
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check32("V8U C/D leave IQ only on dual capture",
                 {28'b0, issue_count}, 32'd0);
      $display("[V8U-F4-PARTIAL-CONSUME] no_singleton_turnover=1 iq_pop2=0 old_pair_drains=2 new_pair_capture=1 PASS");
      reset_dut();
    end
  endtask

  // v8s/F2 canonical dual-memory integration.  This focused path enables the
  // production parameter and drives both bridge-facing request/response
  // identities; the default regression remains on the legacy parameter.
  task automatic run_v8s_dual_memory_core_integration;
    reg [PRODUCER_ID_W-1:0] diff_pid0;
    reg [PRODUCER_ID_W-1:0] diff_pid1;
    reg [ROB_INDEX_W-1:0] diff_rob0;
    reg [ROB_INDEX_W-1:0] diff_rob1;
    reg [PRODUCER_ID_W-1:0] kill_pid0;
    reg [PRODUCER_ID_W-1:0] kill_pid1;
    reg [1:0] kill_kind0;
    reg [1:0] kill_kind1;
    reg [4:0] kill_token0;
    reg [4:0] kill_token1;
    reg [1:0] kill_epoch0;
    reg [1:0] kill_epoch1;
    reg [`XLEN-1:0] kill_tval0;
    reg [`XLEN-1:0] kill_tval1;
    integer wait_i;
    begin
      tb_check32("V8S production parameter enabled",
                 TB_ENABLE_DUAL_MEM, 32'd1);

      // Different banks: both captured-data AGUs must produce a stable valid
      // while backpressured, then both requests fire and both responses use
      // the global two-slot WB allocator in one cycle.
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c000,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd1, 64'h0000_0000_0000_0200);
      set_dispatch1(64'h0000_0000_8000_c004,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd2, 64'h0000_0000_0000_0208);
      #1;
      tb_check1("V8S diff-bank dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8S diff-bank dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("V8S diff-bank pair selected", dut.iq_memory_pair_w, 1'b1);
      tb_check1("V8S diff-bank capture0 candidate",
                dut.mem_issue_res_capture_candidate_w, 1'b1);
      tb_check1("V8S diff-bank capture1 candidate",
                dut.mem_issue1_res_capture_candidate_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S diff-bank reservation0 valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V8S diff-bank reservation1 valid",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V8S bank0 valid independent of ready", mem_req_valid, 1'b1);
      tb_check1("V8S bank1 valid independent of ready", mem1_req_valid, 1'b1);
      tb_check64("V8S bank0 captured address", mem_req_addr,
                 64'h0000_0000_0000_0200);
      tb_check64("V8S bank1 captured address", mem1_req_addr,
                 64'h0000_0000_0000_0208);
      tb_check1("V8S request owner tokens differ",
                mem_req_owner_token != mem1_req_owner_token, 1'b1);
      diff_pid0 = dut.mem_issue_res_producer_id_q;
      diff_pid1 = dut.mem_issue1_res_producer_id_q;
      diff_rob0 = dut.mem_issue_res_rob_idx_q;
      diff_rob1 = dut.mem_issue1_res_rob_idx_q;
      tb_check1("V8S request full PIDs differ", diff_pid0 != diff_pid1, 1'b1);

      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S bank0 request fire", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8S bank1 request fire", dut.mem1_req_fire_any_w, 1'b1);
      tb_check1("V8S reservation0 exact consume",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("V8S reservation1 exact consume",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S diff-bank reservation0 drained",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("V8S diff-bank reservation1 drained",
                dut.mem_issue1_res_valid_q, 1'b0);
      tb_check32("V8S bank0 MIQ count", dut.miq_count_w, 32'd1);
      tb_check32("V8S bank1 MIQ count", dut.miq1_count_w, 32'd1);
      tb_check1("V8S bank0 expected tuple live", mem_expected_valid, 1'b1);
      tb_check1("V8S bank1 expected tuple live", mem1_expected_valid, 1'b1);
      tb_check1("V8S bank0 PID reaches MIQ",
                dut.mem_completion_producer_id_w == diff_pid0, 1'b1);
      tb_check1("V8S bank1 PID reaches MIQ",
                dut.mem1_completion_producer_id_w == diff_pid1, 1'b1);

      v8v_record_load_head_order(
          "V8S diff-bank", 1'b1, 64'h0000_0000_0000_0200,
          1'b1, 64'h0000_0000_0000_0208);

      mem_rsp_rdata = 64'h1111_2222_3333_4444;
      mem1_rsp_rdata = 64'haaaa_bbbb_cccc_dddd;
      mem_rsp_valid = 1'b1;
      mem1_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S simultaneous bank0 response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S simultaneous bank1 response ready", mem1_rsp_ready, 1'b1);
      tb_check1("V8S bank0 owns WB0", dut.mem_rsp_to_wb0_w, 1'b1);
      tb_check1("V8S bank1 owns WB1", dut.mem1_rsp_to_wb1_w, 1'b1);
      tb_check1("V8S simultaneous WB0 valid", dut.wb0_valid_w, 1'b1);
      tb_check1("V8S simultaneous WB1 valid", dut.wb1_valid_w, 1'b1);
      tb_check32("V8S WB0 exact ROB", dut.wb0_rob_idx_w, diff_rob0);
      tb_check32("V8S WB1 exact ROB", dut.wb1_rob_idx_w, diff_rob1);
      tb_check64("V8S WB0 load data", dut.wb0_data_w,
                 64'h1111_2222_3333_4444);
      tb_check64("V8S WB1 load data", dut.wb1_data_w,
                 64'haaaa_bbbb_cccc_dddd);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      mem1_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S ordered commit0", commit0_valid, 1'b1);
      tb_check1("V8S ordered commit1", commit1_valid, 1'b1);
      tb_check64("V8S ordered commit0 data", commit0_data,
                 64'h1111_2222_3333_4444);
      tb_check64("V8S ordered commit1 data", commit1_data,
                 64'haaaa_bbbb_cccc_dddd);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S diff-bank ROB drains", rob_count, 32'd0);
      tb_check32("V8S diff-bank bank0 MIQ drains", dut.miq_count_w, 32'd0);
      tb_check32("V8S diff-bank bank1 MIQ drains", dut.miq1_count_w, 32'd0);

      // Same bank: age arbitration permits only the older request on the
      // first edge.  The younger reservation remains exact and advances on
      // the following edge; both responses then retire in program order.
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c100,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd3, 64'h0000_0000_0000_0300);
      set_dispatch1(64'h0000_0000_8000_c104,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd4, 64'h0000_0000_0000_0320);
      #1;
      tb_check1("V8S same-bank dispatch0 ready", dispatch0_ready, 1'b1);
      tb_check1("V8S same-bank dispatch1 ready", dispatch1_ready, 1'b1);
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      #1;
      tb_check1("V8S same-bank reservation0 valid",
                dut.mem_issue_res_valid_q, 1'b1);
      tb_check1("V8S same-bank reservation1 valid",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V8S same-bank only bank0 valid", mem_req_valid, 1'b1);
      tb_check1("V8S same-bank no bank1 valid", mem1_req_valid, 1'b0);
      tb_check64("V8S same-bank older selected", mem_req_addr,
                 64'h0000_0000_0000_0300);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S same-bank older consumes",
                dut.mem_issue_res_consume_fire_w, 1'b1);
      tb_check1("V8S same-bank younger held",
                dut.mem_issue1_res_consume_fire_w, 1'b0);
      `TB_TICK(clk);
      #1;
      tb_check1("V8S same-bank older reservation drains",
                dut.mem_issue_res_valid_q, 1'b0);
      tb_check1("V8S same-bank younger reservation remains",
                dut.mem_issue1_res_valid_q, 1'b1);
      tb_check1("V8S same-bank younger request visible", mem_req_valid, 1'b1);
      tb_check1("V8S same-bank still no bank1 request", mem1_req_valid, 1'b0);
      tb_check64("V8S same-bank younger selected", mem_req_addr,
                 64'h0000_0000_0000_0320);
      tb_check1("V8S same-bank younger consumes next edge",
                dut.mem_issue1_res_consume_fire_w, 1'b1);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S same-bank two MIQ entries", dut.miq_count_w, 32'd2);
      tb_check32("V8S same-bank peer MIQ empty", dut.miq1_count_w, 32'd0);

      v8v_record_load_head_order(
          "V8S same-bank older", 1'b1, 64'h0000_0000_0000_0300,
          1'b0, {`XLEN{1'b0}});

      mem_rsp_rdata = 64'h0102_0304_0506_0708;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S same-bank older response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S same-bank older WB", dut.wb0_valid_w, 1'b1);
      tb_check64("V8S same-bank older WB data", dut.wb0_data_w,
                 64'h0102_0304_0506_0708);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S same-bank older commit", commit0_valid, 1'b1);
      tb_check64("V8S same-bank older commit data", commit0_data,
                 64'h0102_0304_0506_0708);
      v8v_record_load_head_order(
          "V8S same-bank younger", 1'b1, 64'h0000_0000_0000_0320,
          1'b0, {`XLEN{1'b0}});
      mem_rsp_rdata = 64'h1112_1314_1516_1718;
      mem_rsp_valid = 1'b1;
      #1;
      tb_check1("V8S same-bank younger response ready", mem_rsp_ready, 1'b1);
      tb_check1("V8S same-bank younger WB", dut.wb0_valid_w, 1'b1);
      tb_check64("V8S same-bank younger WB data", dut.wb0_data_w,
                 64'h1112_1314_1516_1718);
      `TB_TICK(clk);
      mem_rsp_valid = 1'b0;
      #1;
      tb_check1("V8S same-bank younger commit", commit0_valid, 1'b1);
      tb_check64("V8S same-bank younger commit data", commit0_data,
                 64'h1112_1314_1516_1718);
      `TB_TICK(clk);
      #1;
      tb_check32("V8S same-bank ROB drains", rob_count, 32'd0);
      tb_check32("V8S same-bank MIQ drains", dut.miq_count_w, 32'd0);

      // Full flush cuts architectural effects and compacts ordinary MIQ
      // entries.  The two bridges retain exact physical identities and return
      // them through independent drop terminals; only those drops may free the
      // tracker owners.
      reset_dut();
      mem_req_ready = 1'b0;
      mem1_req_ready = 1'b0;
      set_dispatch0(64'h0000_0000_8000_c200,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd5, 64'h0000_0000_0000_0400);
      set_dispatch1(64'h0000_0000_8000_c204,
                    make_load_ctrl(`MEM_SIZE_DWORD, 1'b1),
                    5'd0, 5'd0, 5'd6, 64'h0000_0000_0000_0408);
      #1;
      `TB_TICK(clk);
      clear_dispatch();
      `TB_TICK(clk);
      mem_req_ready = 1'b1;
      mem1_req_ready = 1'b1;
      #1;
      tb_check1("V8S kill seed bank0 fire", dut.mem_req_fire_any_w, 1'b1);
      tb_check1("V8S kill seed bank1 fire", dut.mem1_req_fire_any_w, 1'b1);
      `TB_TICK(clk);
      #1;
      kill_pid0 = dut.mem_completion_producer_id_w;
      kill_pid1 = dut.mem1_completion_producer_id_w;
      kill_kind0 = mem_expected_owner_kind;
      kill_kind1 = mem1_expected_owner_kind;
      kill_token0 = mem_expected_owner_token;
      kill_token1 = mem1_expected_owner_token;
      kill_epoch0 = mem_expected_mmu_epoch;
      kill_epoch1 = mem1_expected_mmu_epoch;
      kill_tval0 = mem_expected_fault_tval;
      kill_tval1 = mem1_expected_fault_tval;
      flush = 1'b1;
      #1;
      tb_check1("V8S flush masks bank0 request", mem_req_valid, 1'b0);
      tb_check1("V8S flush masks bank1 request", mem1_req_valid, 1'b0);
      `TB_TICK(clk);
      flush = 1'b0;
      #1;
      tb_check32("V8S flush clears ROB", rob_count, 32'd0);
      tb_check1("V8S flush compacts bank0 MIQ", mem_expected_valid, 1'b0);
      tb_check1("V8S flush compacts bank1 MIQ", mem1_expected_valid, 1'b0);
      tb_check32("V8S flush bank0 MIQ empty", dut.miq_count_w, 32'd0);
      tb_check32("V8S flush bank1 MIQ empty", dut.miq1_count_w, 32'd0);
      tb_check1("V8S bank0 owner awaits exact drop",
                dut.mem_owner_live_mask_w[kill_token0], 1'b1);
      tb_check1("V8S bank1 owner awaits exact drop",
                dut.mem_owner_live_mask_w[kill_token1], 1'b1);
      tb_check1("V8S killed full PIDs remain distinct",
                kill_pid0 != kill_pid1, 1'b1);
      tb_mem_drop0_owner_kind = kill_kind0;
      tb_mem_drop0_owner_token = kill_token0;
      tb_mem_drop0_mmu_epoch = kill_epoch0;
      tb_mem_drop0_fault_tval = kill_tval0;
      tb_mem1_drop0_owner_kind = kill_kind1;
      tb_mem1_drop0_owner_token = kill_token1;
      tb_mem1_drop0_mmu_epoch = kill_epoch1;
      tb_mem1_drop0_fault_tval = kill_tval1;
      tb_mem_drop0_valid = 1'b1;
      tb_mem1_drop0_valid = 1'b1;
      #1;
      tb_check1("V8S bank0 drop reaches collector",
                dut.mem_terminal_ingress_valid_w[2], 1'b1);
      tb_check1("V8S bank1 drop reaches collector",
                dut.mem_terminal_ingress_valid_w[4], 1'b1);
      tb_check1("V8S bridge drops have no WB0", dut.wb0_valid_w, 1'b0);
      tb_check1("V8S bridge drops have no WB1", dut.wb1_valid_w, 1'b0);
      `TB_TICK(clk);
      tb_mem_drop0_valid = 1'b0;
      tb_mem1_drop0_valid = 1'b0;
      #1;
      wait_i = 0;
      while (((dut.mem_owner_live_count_w != 0) ||
              (dut.mem_terminal_pending_count_w != 0)) &&
             (wait_i < 12)) begin
        `TB_TICK(clk);
        #1;
        wait_i = wait_i + 1;
      end
      tb_check32("V8S killed bank0 MIQ drains", dut.miq_count_w, 32'd0);
      tb_check32("V8S killed bank1 MIQ drains", dut.miq1_count_w, 32'd0);
      tb_check32("V8S killed owners drain", dut.mem_owner_live_count_w, 32'd0);
      tb_check32("V8S killed terminal collector drains",
                 dut.mem_terminal_pending_count_w, 32'd0);
      tb_check1("V8S killed responses never commit", commit0_valid, 1'b0);
      tb_check1("V8S killed responses never dual-commit", commit1_valid, 1'b0);

      run_v8s_reverse_bank_backpressure();
      run_v8s_rob_wrap_age();
      run_v8s_dual_ex_wb_hold();
      run_v8s_dual_store_probe();
      run_v8s_singleton_exclusion();
      run_v8s_selective_kill_race();
      run_v8v_checkpoint_restore_store_drain();
      run_v8v_checkpoint_restore_lq_drain();
      run_v8v_lq_retire_authority();
      run_v8u_partial_consume_no_turnover();
      run_v8u_current_pop_next_head_query();
      run_v9p_replay_capacity_admission();
      run_v8t_final_pa_retry_lifecycle();
      $display("[V8S-DUAL-MEMORY-CORE] diff_bank_dual_req=1 reverse_mapping=1 consume_masks=4 same_bank_age=1 rob_wrap_age=1 dual_rsp=1 one_credit_backpressure=1 dual_ex_full_hold=1 dual_store_fill=1 dual_store_fault=1 singleton_priority=1 release_lookthrough=0 selective_kill=1 flush_exact_drop=1 checkpoint_store_drain=1 checkpoint_lq_drain=1 checkpoint_owner_recovery=1 lq_retire_authority=1 full_pid=1 PASS");
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
    run_hist_ser_qh_younger_store_cycle();
`elsif V11R_INT_LANE1_PACKET_FOCUSED
    run_v11r_int_lane1_packet_semantic();
`elsif V11Q_INT_LANE0_PACKET_FOCUSED
    run_v11q_int_lane0_packet_semantic();
`elsif V11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED
    run_v11p_checkpoint_irrevocable_write_semantic();
`elsif V11O_MEMORY_BUFFER_TOKEN_FOCUSED
    run_v11o_memory_buffer_token_semantic();
`elsif V11N_MEMORY_PENDING_HOLDER_FOCUSED
    run_v11n_memory_pending_holder_semantic();
`elsif V11M_MEMORY_RESERVATION_HOLDER_FOCUSED
    run_v11m_memory_reservation_holder_semantic();
`elsif V11L_MEMORY_RETRY_HOLDER_FOCUSED
    run_v11l_memory_retry_holder_semantic();
`elsif V9R_SQ_RETRY_C0_FOCUSED
    run_v9r_sq_retry_c0_handoff();
`elsif V11I_TERMINAL_LIFECYCLE_FOCUSED
    run_v11i_terminal_lifecycle_after_lq_clear();
`elsif V8S_DUAL_MEMORY_FOCUSED
    run_v8s_dual_memory_core_integration();
`elsif V8W_MEMORY_RECOVERY_FOCUSED
    run_v8w_miq_drop_recovery_contract();
    run_v8w_late_old_drop_new_head_isolation();
`elsif V8Y_SPECULATION_RECOVERY_FOCUSED
    run_v8y_oldest_control_recovery();
    run_v8d_int_ex_completion_kill_cut();
    run_v8d_int_ex_kill_age_matrix();
    run_v8x_backend_bridge_recovery_contract();
    $display("[V8Y-SPECULATION-RECOVERY] multi_control=1 oldest_branch=1 selective_ex=1 axi_drain=1 complete_violations=0 retire_violations=0 ghosts=0 PASS");
`elsif V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
    run_v8x_backend_bridge_recovery_contract();
`elsif V8P_PAIR_MATRIX_FOCUSED
    run_v8p_pair_matrix_contract();
`elsif V9F_MEMORY_ISSUE_LIFECYCLE_FOCUSED
    run_v9f_memory_issue_lifecycle();
`else
`ifdef V8N_TRUE_OOO_LONG_LATENCY_FOCUSED
    run_v8n_true_ooo_long_latency();
`elsif V8M_SELECTIVE_SCHEDULING_FOCUSED
    run_v8m_selective_scheduling();
`elsif V8L_GLOBAL_LEASE_FOCUSED
    run_v8l_transient_holder_census();
`elsif V8K_PENDING_CSR_LEASE_FOCUSED
    run_v8k_pending_csr_lease_fence();
`elsif V8J_BRANCH_RESOLVE_AUTH_FOCUSED
    run_v8j_branch_resolve_authorization();
`elsif INT_EX_KILL_CUT_FOCUSED
    run_v8d_int_ex_completion_kill_cut();
    run_v8d_int_ex_kill_age_matrix();
`elsif V8G_MEMORY_PRODUCER_LEASE_FOCUSED
    run_v8g_mem_ingress_lease_reauth();
    run_v8g_mem_tracker_tag_quarantine();
    run_v8g_mem_continuous_wb_competition();
    run_s2_g1_effective_kill_response_contract();
    run_s2_g1_amo_restore_and_grant_contract();
`elsif INT_EX_PRODUCER_AUTH_FOCUSED
    run_v8f_early_wakeup_generation_mismatch();
    run_v8f_early_wakeup1_generation_mismatch();
    run_v8f_ex0_completion_generation_mismatch();
    run_v8f_ex1_completion_generation_mismatch();
    run_v8f_mem_reservation_producer_id_contract();
    run_v8d_int_ex_kill_age_matrix();
`elsif V8H_LONGOP_PRODUCER_LEASE_FOCUSED
    run_v8h_longop_same_edge_claim_matrix();
`elsif V8I_FP_PRODUCER_LEASE_FOCUSED
    run_v8i_fp_pending_owner_and_credit();
    run_v8i_fifo_same_slot_case({{(PRODUCER_GEN_W){1'b0}}, 4'd3},
                                {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1, 4'd1},
                                4'd1, 1'b0);
    run_v8i_fifo_same_slot_case({{(PRODUCER_GEN_W){1'b0}}, 4'd1},
                                {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1, 4'd3},
                                4'd1, 1'b1);
    run_v8i_fifo_same_slot_case({{(PRODUCER_GEN_W){1'b0}}, 4'd3},
                                {{(PRODUCER_GEN_W-1){1'b0}}, 1'b1, 4'd5},
                                4'd8, 1'b0);
    run_v8i_generation_separated_transport();
`elsif INT_WB_VALID_SOURCE_FOCUSED
    run_p0_wb_write_valid_source_matrix();
`elsif INT_WB_WRITE_VALID_EQUIV_NEGATIVE
    // 只 force shadow，功能 write-enable/PRF/ROB 都不受扰动；精确证明
    // cycle-exact equivalence 断言对单拍 mismatch 非真空。
    if (dut.gpr_wb0_write_valid_w || dut.gpr_wb0_legacy_write_valid_w)
      $fatal(1, "[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE-SETUP] idle values are not zero");
    force dut.gpr_wb0_legacy_write_valid_w = 1'b1;
    #1;
    if (dut.gpr_wb0_write_valid_w !== 1'b0)
      $fatal(1, "[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE-SETUP] functional valid was perturbed");
    $display("[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE] forced local=%b legacy=%b",
             dut.gpr_wb0_write_valid_w,
             dut.gpr_wb0_legacy_write_valid_w);
    `TB_TICK(clk);
    release dut.gpr_wb0_legacy_write_valid_w;
    $display("[INT-WB0-WRITE-VALID-EQUIV-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`elsif INT_WB_SOURCE_ONEHOT_NEGATIVE
    // 两个 source select 重叠，但各自 pdest=p0 且 formal valid 被静默；因此
    // 只应命中 onehot0，不会伪造 ROB completion 或 equivalence mismatch。
    force dut.mem_rsp_to_wb0_w = 1'b1;
    force dut.clmul_rsp_to_wb0_w = 1'b1;
    force dut.mem_rsp_int_pdest_w = {PHY_REG_ADDR_W{1'b0}};
    force dut.clmul_resp_pdest_w = {PHY_REG_ADDR_W{1'b0}};
    force dut.wb0_valid_w = 1'b0;
    #1;
    if ((dut.wb0_source_count_w !== 3'd2) ||
        dut.gpr_wb0_write_valid_w ||
        dut.gpr_wb0_legacy_write_valid_w)
      $fatal(1, "[INT-WB0-SOURCE-ONEHOT0-NEGATIVE-SETUP] expected isolated two-source overlap");
    $display("[INT-WB0-SOURCE-ONEHOT0-NEGATIVE] forced sources=%b",
             dut.wb0_source_onehot_w);
    `TB_TICK(clk);
    release dut.mem_rsp_to_wb0_w;
    release dut.clmul_rsp_to_wb0_w;
    release dut.mem_rsp_int_pdest_w;
    release dut.clmul_resp_pdest_w;
    release dut.wb0_valid_w;
    $display("[INT-WB0-SOURCE-ONEHOT0-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`else
`ifdef T3U_CSR_QH_DIRECTED
    run_t3u_csr_queue_head_mem_admission();
`else
    run_v8k_pending_csr_lease_fence();
    run_v8j_branch_resolve_authorization();
    tb_check32("initial freelist count", {25'b0, free_count}, 32'd32);
    tb_check32("initial rob count", {27'b0, rob_count}, 32'd0);
    tb_check32("initial issue count", {28'b0, issue_count}, 32'd0);

`ifdef INT_DISPATCH_PACKET_PACKED_NEGATIVE
    // 独立负探针：生产前端保证 packet densely packed；这里在 IntBackend
    // 边界直接制造唯一违约形状 (valid0,valid1)=(0,1)，证明 OOO_ASSERT
    // 的 carrying-contract marker 有牙。宏默认不定义，常规模块回归不进入本臂。
    clear_dispatch();
    set_dispatch1(32'h8000_0df4,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd6, 64'd1);
    dispatch0_valid = 1'b0;
    #1;
    if (dispatch0_valid || !dispatch1_valid || dut.dispatch0_fire_w ||
        dut.dispatch1_fire_w)
      $fatal(1, "[INT-DISPATCH-PACKET-PACKED-NEGATIVE-SETUP] expected valid={0,1} fire={0,0}, got valid={%0b,%0b} fire={%0b,%0b}",
             dispatch0_valid, dispatch1_valid,
             dut.dispatch0_fire_w, dut.dispatch1_fire_w);
    $display("[INT-DISPATCH-PACKET-PACKED-NEGATIVE] presenting valid={%0b,%0b} fire={%0b,%0b}",
             dispatch0_valid, dispatch1_valid,
             dut.dispatch0_fire_w, dut.dispatch1_fire_w);
    `TB_TICK(clk);
    $display("[INT-DISPATCH-PACKET-PACKED-NEGATIVE-DONE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef FP_PAIR_ATOMIC_NEGATIVE
    // 非真空负探针：先建立有容量的合法 mandatory 双 FP packet，确认两 lane
    // 原本都会 fire，再只压掉 lane1 的消费边界 fire，跨沿验证原子断言有牙。
    set_fp_binary0(32'h8000_0e00, 7'b0000001,
                   5'd0, 5'd0, 5'd9, 1'b1);
    set_fp_binary1(32'h8000_0e04, 7'b0000001,
                   5'd0, 5'd0, 5'd10, 1'b1);
    #1;
    if (!(dispatch0_ready && dispatch1_ready &&
          dut.dispatch0_fire_w && dut.dispatch1_fire_w))
      $fatal(1, "[FP-PAIR-ATOMIC-NEGATIVE-SETUP] legal pair did not reach dual-fire window");
    force dut.dispatch1_fire_w = 1'b0;
    $display("[FP-PAIR-ATOMIC-NEGATIVE] forced fire={%0b,%0b} in legal mandatory window",
             dut.dispatch0_fire_w, dut.dispatch1_fire_w);
    `TB_TICK(clk);
    release dut.dispatch1_fire_w;
    #1;
    $display("[FP-PAIR-ATOMIC-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef INT_WB_PDEST_UNIQUE_NEGATIVE
    // 非真空负探针：lane0 是真实非零整数目的 ALU，lane1 是无目的但仍经 EX
    // 正式完成的 ALU。这样双 formal-WB valid 真实成立而 lane1 fast valid 为 0；
    // 仅 force formal wb1 pdest 即可孤立命中 unique marker，不扰动 fast-subset 断言。
    set_dispatch0(32'h8000_0e10,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd5, 64'd17);
    set_dispatch1(32'h8000_0e14,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b0),
                  5'd0, 5'd0, 5'd0, 64'd23);
    #1;
    if (!(dispatch0_ready && dispatch1_ready))
      $fatal(1, "[INT-WB-PDEST-UNIQUE-NEGATIVE-SETUP] legal dual dispatch not ready");
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    if (!(dut.issue0_valid_w && dut.issue1_valid_w))
      $fatal(1, "[INT-WB-PDEST-UNIQUE-NEGATIVE-SETUP] legal dual EX issue window absent");
    `TB_TICK(clk);
    #1;
    if (!(dut.wb0_valid_w && dut.wb1_valid_w &&
          (dut.wb0_pdest_w != {PHY_REG_ADDR_W{1'b0}}) &&
          (dut.wb1_pdest_w == {PHY_REG_ADDR_W{1'b0}})))
      $fatal(1, "[INT-WB-PDEST-UNIQUE-NEGATIVE-SETUP] expected dual formal-WB/nonzero-zero pdest window absent");
    force dut.wb1_pdest_w = dut.wb0_pdest_w;
    $display("[INT-WB-PDEST-UNIQUE-NEGATIVE] forced formal pdest={%0d,%0d} valid={%0b,%0b}",
             dut.wb0_pdest_w, dut.wb1_pdest_w,
             dut.wb0_valid_w, dut.wb1_valid_w);
    // flush 只用于静默同沿 ROB slot-identity 哨兵；EX_q 的双 formal-WB valid
    // 在该沿前仍真实有效，IntBackend unique 断言刻意不受 flush 门控。
    flush = 1'b1;
    `TB_TICK(clk);
    release dut.wb1_pdest_w;
    #1;
    $display("[INT-WB-PDEST-UNIQUE-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

`ifdef INT_ALU_TERMINAL_CAPABILITY_NEGATIVE
    // R3.4 non-vacuous negative: start from a real dual-simple issue window,
    // then violate only the physical ALU-terminal allow-list.  The terminal's
    // removed complex/WBU arms must not turn malformed upstream control into
    // a silently accepted completion.
    set_dispatch0(32'h8000_0e20,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd7, 64'd29);
    set_dispatch1(32'h8000_0e24,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd8, 64'd31);
    #1;
    if (!(dispatch0_ready && dispatch1_ready))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] dual-simple dispatch not ready");
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    if (!(dut.issue1_valid_w && dut.issue1_fire_w))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] live ALU-terminal issue window absent");
    force dut.issue1_ctrl_w[`CTRL_BITMANIP_BIT] = 1'b1;
    $display("[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-BITMANIP] forced live ctrl=%h",
             dut.issue1_ctrl_w);
    `TB_TICK(clk);
    release dut.issue1_ctrl_w[`CTRL_BITMANIP_BIT];

    reset_dut();
    set_dispatch0(32'h8000_0e30,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd9, 64'd37);
    set_dispatch1(32'h8000_0e34,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd10, 64'd41);
    #1;
    if (!(dispatch0_ready && dispatch1_ready))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] WB-select pair not ready");
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    if (!(dut.issue1_valid_w && dut.issue1_fire_w))
      $fatal(1, "[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-SETUP] WB-select issue window absent");
    force dut.issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB] = `WB_SEL_PC4;
    $display("[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-WBSEL] forced live ctrl=%h",
             dut.issue1_ctrl_w);
    `TB_TICK(clk);
    release dut.issue1_ctrl_w[`CTRL_WB_SEL_MSB:`CTRL_WB_SEL_LSB];
    #1;
    $display("[INT-ALU-TERMINAL-CAPABILITY-NEGATIVE-DONE] completed two assertion edges");
    $finish_and_return(0);
`endif

`ifdef RAW_I1_NEGATIVE_PROBE
    // 非真空负探针：先建立两个合法 independent integer issue lane，再只 force
    // issue1 enabled source tag 撞 issue0 integer pdest，证明 RAW-I1 立即断言有牙。
    set_dispatch0(32'h8000_0f00,
                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2, `ALU_OP_ADD,
                                1'b1, 1'b1, 1'b1),
                  5'd1, 5'd2, 5'd5, 64'd0);
    set_dispatch1(32'h8000_0f04,
                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_RS2, `ALU_OP_ADD,
                                1'b1, 1'b1, 1'b1),
                  5'd3, 5'd4, 5'd6, 64'd0);
    #1;
    tb_check1("RAW-I1 probe dispatch0 ready", dispatch0_ready, 1'b1);
    tb_check1("RAW-I1 probe dispatch1 ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("RAW-I1 probe reaches issue0", dut.issue0_valid_w, 1'b1);
    tb_check1("RAW-I1 probe reaches issue1", dut.issue1_valid_w, 1'b1);
    force dut.issue1_src1_preg_w = dut.issue0_pdest_w;
    $display("[RAW-I1-NEGATIVE-PROBE] forced issue1 src1=%0d to issue0 pdest=%0d",
             dut.issue1_src1_preg_w, dut.issue0_pdest_w);
    `TB_TICK(clk);
    #1;
    $finish_and_return(0);
`endif

    run_t4h_store_probe_pma_fault_precise();
    run_t4n_store_b_error_precise();
    run_r4_s0_store_class_propagation();
    run_t4n_page_end_store_local_exception(1'b0);
    run_t4n_page_end_store_local_exception(1'b1);
    run_t4n_b_local_terminal_collision(1'b0);
    run_t4n_b_local_terminal_collision(1'b1);
    run_t4n_older_alu_probe_fault_exception_order();
    run_t4n_sq_checkpoint_restore_no_fire();
    run_t4n_two_store_priority_order();
    run_t4n_t4m_store_before_device_candidate(
        1'b1, 64'h0000_0000_8000_5000);
    run_t4n_t4m_store_before_device_candidate(
        1'b0, 64'h0000_0000_1000_0000);
    run_s1_sq_forward_bypasses_blind_barrier();

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
    // R3.2: producer actual fire sets sticky ready at the edge that also
    // registers its EX result.  The dependent selects in the following cycle
    // and consumes only the registered EX forwarding payload.
    tb_check32("dependent pair queued", {28'b0, issue_count}, 32'd2);
    `TB_TICK(clk);
    #1;
    tb_check32("consumer resident during lookahead select",
               {28'b0, issue_count}, 32'd1);
    tb_check1("producer formal WB visible", dut.wb0_valid_w, 1'b1);
    tb_check64("producer formal WB data", dut.wb0_data_w, 64'd7);
    tb_check1("producer does not commit on formal WB", commit0_valid, 1'b0);
    tb_check1("consumer selects one cycle after producer fire",
              dut.issue0_valid_w, 1'b1);
    tb_check1("consumer source hits registered EX0",
              dut.issue0_src1_ex0_fwd_hit_w, 1'b1);
    tb_check64("consumer forwarded source value",
               dut.issue0_src1_data_w, 64'd7);

    `TB_TICK(clk);
    #1;
    tb_check32("consumer leaves IQ after lookahead fire",
               {28'b0, issue_count}, 32'd0);
    tb_check1("producer commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("producer result from ROB Q", commit0_data, 64'd7);
    tb_check1("consumer formal WB visible", dut.wb0_valid_w, 1'b1);
    tb_check64("consumer formal WB uses registered EX forward",
               dut.wb0_data_w, 64'd10);

    `TB_TICK(clk);
    #1;
    tb_check1("consumer commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("consumer result from ROB Q", commit0_data, 64'd10);

    `TB_TICK(clk);
    #1;
    tb_check32("dependent rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("dependent iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("dependent freelist recovers", {25'b0, free_count}, 32'd32);

    run_r3p2_dual_producer_consumer();
    run_r3p2_raw_chain_64();
    run_lane1_prf_wb_wakeup();
    run_t3b_divu_wb0_isolation();
    run_t3b_clmul_wb0_isolation();
    // T3P lane1-simple owner 后 long-op 只从 lane0 发射；旧“DIVU 直接占
    // lane1 并以同拍 ALU 挤到 WB1”的构造已不可达。WB0 sticky 隔离仍由上面
    // DIVU/CLMUL 两个真实 long-op 用例覆盖，双 formal-WB 由独立碰撞用例覆盖。
    run_t3b_fp_load_tag_alias_exclusion();
    run_t3b_integer_load_fault_exclusion();
    run_t4s_fp_raw_intent_state_isolation();
    run_t3c_fp_mandatory_pair_atomicity_red();
    run_t3q_fp_issue_stage_contracts();

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

    // T3N：lane0 raw resolve 在 issue 拍只写 coherent PipeStageReg；公开
    // redirect/kill/BPU bundle 下一拍 exactly-once 出现。DispatchBackend 删除旧
    // kill_q 后应在同一 q 拍直接驱动 ROB/IQ kill；stage invalid 后 dirty
    // mispredict payload 绝不能继续产生 kill。
    set_dispatch0(32'h8000_0810,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    // 非零/非默认 metadata 锁住 bundle 字段顺序；pred_taken=1 与错误的
    // pred_npc=0 可同时保持本例为真实 mispredict。
    dispatch0_bht_idx = 10'h2a5;
    dispatch0_pred_taken = 1'b1;
    #1;
    tb_check1("T3N staged branch dispatch ready", dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N branch selected on lane0", dut.issue0_valid_w, 1'b1);
    tb_check1("T3N lane0 control-flow fire", dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check1("T3N public resolve absent in raw issue cycle",
              branch_resolve_valid, 1'b0);
    tb_check1("T3N ROB kill absent before resolve q",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N public resolve valid exactly next cycle",
              branch_resolve_valid, 1'b1);
    tb_check64("T3N staged resolve pc",
               branch_resolve_pc, 64'h0000_0000_8000_0810);
    tb_check64("T3N staged resolve target",
               branch_resolve_next_pc, 64'h0000_0000_8000_0818);
    tb_check1("T3N staged resolve aligned", branch_resolve_misaligned, 1'b0);
    tb_check1("T3N staged resolve mispredict", branch_resolve_mispredict, 1'b1);
    tb_check1("T3N staged resolve branch kind", branch_resolve_is_branch, 1'b1);
    tb_check1("T3N staged resolve taken", branch_resolve_taken, 1'b1);
    tb_check1("T3N staged resolve predicted taken metadata",
              branch_resolve_pred_taken, 1'b1);
    tb_check32("T3N staged resolve BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_02a5);
    tb_check1("T3N resolve q directly drives ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b1);
    tb_check1("T3N branch shares EX boundary cycle", dut.ex0_valid_q, 1'b1);
    tb_check32("T3N resolve/ex ROB identity",
               {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx},
               {{(32-ROB_INDEX_W){1'b0}}, dut.ex0_rob_idx_q});
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N resolve pulse consumed once", branch_resolve_valid, 1'b0);
    tb_check1("T3N dirty payload cannot repeat mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check1("T3N dirty payload cannot repeat ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    repeat (5) begin
      `TB_TICK(clk);
      clear_dispatch();
    end
    #1;
    tb_check32("T3N staged branch ROB drains", {27'b0, rob_count}, 32'd0);
    tb_check32("T3N staged branch IQ drains", {28'b0, issue_count}, 32'd0);
    tb_check32("T3N staged branch freelist recovers",
               {25'b0, free_count}, 32'd32);

    // q 已有效时，flush 必须在同一个组合拍立即屏蔽整包；不能等上升沿，
    // 否则 dirty mispredict 会多打一拍 redirect/kill/BPU update。
    set_dispatch0(32'h8000_0820,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch0_bht_idx = 10'h155;
    dispatch0_pred_taken = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N flush-collision branch reaches raw lane0",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N flush-collision setup has resolve q",
              branch_resolve_valid, 1'b1);
    tb_check1("T3N flush-collision setup has mispredict",
              branch_resolve_mispredict, 1'b1);
    flush = 1'b1;
    #1;
    tb_check1("T3N flush masks resolve valid immediately",
              branch_resolve_valid, 1'b0);
    tb_check64("T3N flush masks resolve pc", branch_resolve_pc, 64'd0);
    tb_check64("T3N flush masks resolve next pc",
               branch_resolve_next_pc, 64'd0);
    tb_check1("T3N flush masks resolve misaligned",
              branch_resolve_misaligned, 1'b0);
    tb_check32("T3N flush masks resolve ROB index",
               {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx}, 32'd0);
    tb_check1("T3N flush masks resolve mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check1("T3N flush masks resolve branch kind",
              branch_resolve_is_branch, 1'b0);
    tb_check1("T3N flush masks resolve taken",
              branch_resolve_taken, 1'b0);
    tb_check1("T3N flush masks resolve pred_taken",
              branch_resolve_pred_taken, 1'b0);
    tb_check32("T3N flush masks resolve BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'd0);
    tb_check1("T3N flush masks direct ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N flush clears resolve stage", branch_resolve_valid, 1'b0);

    // T3Q：checkpoint_restore 可作为模块接口上的独立脉冲出现。即使顶层当前
    // ROB-walk 配置把该链静态关闭，模块也不得在子单元 flush 的同一拍从 IQ
    // pop 一个 long-op，否则上游记为已发射而 MulDiv 会丢弃请求。
    set_dispatch0(32'h8000_0824, make_muldiv_ctrl(),
                  5'd0, 5'd0, 5'd1, 64'd0);
    dispatch0_inst = inst_op(`FUNCT7_MULDIV, 5'd0, 5'd0,
                             3'b101, 5'd1);
    #1;
    tb_check1("T3Q restore collision MulDiv dispatch ready",
              dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3Q restore collision MulDiv selected",
              dut.issue0_is_muldiv_w, 1'b1);
    checkpoint_restore = 1'b1;
    #1;
    tb_check1("T3Q restore masks lane0 ready",
              dut.issue0_ready_w, 1'b0);
    tb_check1("T3Q restore forbids lane0 fire",
              dut.issue0_fire_w, 1'b0);
    tb_check1("T3Q restore forbids MulDiv request valid",
              dut.muldiv_req_valid_w, 1'b0);
    $display("[T3Q-CHECKPOINT-RESTORE-NO-ISSUE] ready=%0b fire=%0b req_valid=%0b",
             dut.issue0_ready_w, dut.issue0_fire_w,
             dut.muldiv_req_valid_w);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check32("T3Q restore leaves MulDiv idle",
               {29'b0, dut.u_muldiv_unit.state_q}, 32'd0);
    reset_dut();

    // checkpoint_restore 与 flush 共享 resolve-stage flush 语义，也必须同拍
    // 屏蔽公开 payload。该 TB 的 recover_gprs 为零，因此碰撞验证后重新 reset
    // 恢复 canonical rename map。
    set_dispatch0(32'h8000_0828,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch0_bht_idx = 10'h0d3;
    dispatch0_pred_taken = 1'b1;
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N checkpoint-collision branch reaches raw lane0",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N checkpoint-collision setup has resolve q",
              branch_resolve_valid, 1'b1);
    checkpoint_restore = 1'b1;
    #1;
    tb_check1("T3N checkpoint masks resolve valid immediately",
              branch_resolve_valid, 1'b0);
    tb_check64("T3N checkpoint masks resolve pc", branch_resolve_pc, 64'd0);
    tb_check64("T3N checkpoint masks resolve next pc",
               branch_resolve_next_pc, 64'd0);
    tb_check1("T3N checkpoint masks resolve mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check32("T3N checkpoint masks resolve ROB index",
               {{(32-ROB_INDEX_W){1'b0}}, branch_resolve_rob_idx}, 32'd0);
    tb_check32("T3N checkpoint masks resolve BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'd0);
    tb_check1("T3N checkpoint masks direct ROB kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    reset_dut();

    // 两条预测正确的顺序分支（均 not-taken）验证 stage 可连续每拍
    // consume/capture，且 lane1 分支先留队、次拍晋升 lane0；两个 payload 不得
    // 合并、丢失或乱序，也都不得触发 kill。
    set_dispatch0(32'h8000_0830,
                  make_branch_ctrl(`CMP_OP_NE),
                  5'd0, 5'd0, 5'd0, 64'd8);
    set_dispatch1(32'h8000_0834,
                  make_branch_ctrl(`CMP_OP_NE),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch0_pred_npc = 64'h0000_0000_8000_0834;
    dispatch1_pred_npc = 64'h0000_0000_8000_0838;
    dispatch0_bht_idx = 10'h155;
    dispatch1_bht_idx = 10'h2aa;
    #1;
    tb_check1("T3N branch pair lane0 dispatch ready", dispatch0_ready, 1'b1);
    tb_check1("T3N branch pair lane1 dispatch ready", dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N first branch issues on lane0", dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check1("T3N second branch not exposed on lane1", dut.issue1_valid_w, 1'b0);
    tb_check1("T3N branch stream has initial stage latency",
              branch_resolve_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N first correct branch resolve", branch_resolve_valid, 1'b1);
    tb_check64("T3N first correct branch pc",
               branch_resolve_pc, 64'h0000_0000_8000_0830);
    tb_check64("T3N first correct branch next pc",
               branch_resolve_next_pc, 64'h0000_0000_8000_0834);
    tb_check1("T3N first correct branch not taken", branch_resolve_taken, 1'b0);
    tb_check1("T3N first correct branch no mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check32("T3N first correct branch keeps lane0 BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_0155);
    tb_check1("T3N second branch promotes while first resolves",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check64("T3N promoted second branch raw pc",
               dut.issue0_pc_w, 64'h0000_0000_8000_0834);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N second correct branch resolve", branch_resolve_valid, 1'b1);
    tb_check64("T3N second correct branch pc",
               branch_resolve_pc, 64'h0000_0000_8000_0834);
    tb_check64("T3N second correct branch next pc",
               branch_resolve_next_pc, 64'h0000_0000_8000_0838);
    tb_check1("T3N second correct branch no mispredict",
              branch_resolve_mispredict, 1'b0);
    tb_check32("T3N promoted branch keeps lane1 BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_02aa);
    tb_check1("T3N correct branch stream never kills",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N two-branch stream ends exactly once",
              branch_resolve_valid, 1'b0);
    repeat (3) begin
      `TB_TICK(clk);
      clear_dispatch();
    end
    #1;
    tb_check32("T3N correct branch pair ROB drains", {27'b0, rob_count}, 32'd0);
    tb_check32("T3N correct branch pair IQ drains", {28'b0, issue_count}, 32'd0);

    // branch 最初是第二候选时必须留队，不能落到 lane1；下一拍它晋升 lane0，
    // 同时允许更年轻 ALU 走 lane1。若该 branch mispredict，年轻 ALU 即使已经
    // 进入 EX/WB，也不得越过 branch 提交。
    reset_dut();
    set_dispatch0(32'h8000_0840,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b0),
                  5'd0, 5'd0, 5'd0, 64'd1);
    set_dispatch1(32'h8000_0844,
                  make_branch_ctrl(`CMP_OP_EQ),
                  5'd0, 5'd0, 5'd0, 64'd8);
    dispatch1_bht_idx = 10'h31c;
    #1;
    tb_check1("T3N second-candidate packet lane0 dispatch ready",
              dispatch0_ready, 1'b1);
    tb_check1("T3N second-candidate packet lane1 dispatch ready",
              dispatch1_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N older ALU owns issue0", dut.issue0_valid_w, 1'b1);
    tb_check64("T3N older ALU issue pc", dut.issue0_pc_w,
               64'h0000_0000_8000_0840);
    tb_check1("T3N second-candidate branch excluded from issue1",
              dut.issue1_valid_w, 1'b0);
    tb_check1("T3N skipped branch was genuinely ready",
              dut.u_dispatch_backend.u_issue_queue.select_base_ready_w[1],
              1'b1);
    tb_check1("T3N skipped ready entry is branch",
              dut.u_dispatch_backend.u_issue_queue.ctrl_q[1][`CTRL_BRANCH_BIT],
              1'b1);
    tb_check32("T3N second-candidate branch remains resident",
               {28'b0, issue_count}, 32'd2);

    set_dispatch0(32'h8000_0848,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM, `ALU_OP_ADD,
                                1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd9, 64'd99);
    #1;
    tb_check1("T3N younger wrong-path ALU dispatch ready",
              dispatch0_ready, 1'b1);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N retained branch promotes to lane0",
              dut.issue0_ctrlflow_fire_w, 1'b1);
    tb_check64("T3N promoted branch raw pc", dut.issue0_pc_w,
               64'h0000_0000_8000_0844);
    tb_check1("T3N younger wrong-path ALU may use lane1",
              dut.issue1_fire_w, 1'b1);
    tb_check64("T3N younger wrong-path ALU raw pc", dut.issue1_pc_w,
               64'h0000_0000_8000_0848);
    tb_check1("T3N promoted branch still observes stage latency",
              branch_resolve_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N promoted branch resolve q valid",
              branch_resolve_valid, 1'b1);
    tb_check64("T3N promoted branch resolve pc", branch_resolve_pc,
               64'h0000_0000_8000_0844);
    tb_check1("T3N promoted branch is a mispredict",
              branch_resolve_mispredict, 1'b1);
    tb_check32("T3N second-candidate branch keeps BHT metadata",
               {{(32-`BPU_BHT_INDEX_W){1'b0}}, branch_resolve_bht_idx},
               32'h0000_031c);
    tb_check1("T3N promoted branch q drives kill",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b1);
    tb_check1("T3N wrong-path ALU reached EX before kill", dut.ex1_valid_q, 1'b1);
    tb_check32("T3N wrong-path EX keeps younger ROB identity",
               {{(32-ROB_INDEX_W){1'b0}}, dut.ex1_rob_idx_q}, 32'd2);
    tb_check1("T3N q kill suppresses head commit", commit0_valid, 1'b0);
    tb_check1("T3N q kill suppresses second commit", commit1_valid, 1'b0);
    `TB_TICK(clk);
    clear_dispatch();
    #1;
    tb_check1("T3N promoted resolve exactly once", branch_resolve_valid, 1'b0);
    tb_check1("T3N promoted kill exactly once",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    tb_check1("T3N wrong-path cannot commit in first walk cycle",
              (commit0_valid && (commit0_pc == 64'h0000_0000_8000_0848)) ||
              (commit1_valid && (commit1_pc == 64'h0000_0000_8000_0848)),
              1'b0);
    repeat (5) begin
      `TB_TICK(clk);
      clear_dispatch();
      #1;
      tb_check1("T3N wrong-path never commits during recovery",
                (commit0_valid && (commit0_pc == 64'h0000_0000_8000_0848)) ||
                (commit1_valid && (commit1_pc == 64'h0000_0000_8000_0848)),
                1'b0);
    end
    tb_check32("T3N second-candidate ROB drains",
               {27'b0, rob_count}, 32'd0);
    tb_check32("T3N second-candidate IQ drains",
               {28'b0, issue_count}, 32'd0);
    tb_check32("T3N second-candidate freelist recovers",
               {25'b0, free_count}, 32'd32);

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
    tb_check1("bitmanip setup formal WB visible", dut.wb0_valid_w, 1'b1);
    tb_check1("bitmanip setup does not commit on formal WB",
              commit0_valid, 1'b0);
    `TB_TICK(clk);
    #1;
    tb_check1("bitmanip setup commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("bitmanip setup commit data from ROB Q",
               commit0_data, 64'hf0f1_0001_0000_0000);
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
    tick_lane0_serial_pair_to_commit("T3P bitmanip clz ctz",
                                     32'd0, 32'd32);

    set_dispatch0(32'h8000_1820, make_bitmanip_ctrl(),
                  5'd17, 5'd0, 5'd20, 64'd0);
    dispatch0_inst = inst_op_imm(7'h30, 5'h02, 5'd17,
                                 `FUNCT3_SLL, 5'd20);
    set_dispatch1(32'h8000_1824, make_bitmanip_ctrl(),
                  5'd0, 5'd0, 5'd21, 64'd0);
    dispatch1_inst = inst_op_imm(7'h30, 5'h00, 5'd0,
                                 `FUNCT3_SLL, 5'd21);
    tick_lane0_serial_pair_to_commit("T3P bitmanip cpop clz-zero",
                                     32'd10, 32'd64);

    set_dispatch0(32'h8000_1840,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                `ALU_OP_COPY_B, 1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd22, 64'h1234_5678_9abc_def0);
    set_dispatch1(32'h8000_1844,
                  make_alu_ctrl(`OP1_SEL_ZERO, `OP2_SEL_IMM,
                                `ALU_OP_COPY_B, 1'b0, 1'b0, 1'b1),
                  5'd0, 5'd0, 5'd23, 64'hfedc_ba98_7654_3210);
    tick_dispatch_to_commit("clmul setup operands",
                            64'h1234_5678_9abc_def0,
                            64'hfedc_ba98_7654_3210);

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
	    t3g_load0_pdest = dut.dispatch0_pdest_w;
	    // 【P5 刀 B】load 不再 dispatch 拍直通:req 在 issue 拍(次拍)组合出 AGU 才可见。
	    tb_check1("no same-cycle load request", mem_req_valid, 1'b0);
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("T3S buffer seed capture has no early request",
	              mem_req_valid, 1'b0);
	    tb_check1("T3S buffer seed reservation capture pending",
	              dut.mem_issue_res_capture_w, 1'b1);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("buffer seed load request visible", mem_req_valid, 1'b1);
	    tb_check1("buffer seed load is read", mem_req_write, 1'b0);
	    tb_check32("buffer seed load addr", mem_req_addr, 32'h8000_0270);

	    set_dispatch0(32'h8000_2604,
	                  make_load_ctrl(`MEM_SIZE_HALF, 1'b1),
	                  5'd0, 5'd0, 5'd16, 32'h8000_0276);
	    #1;
	    tb_check1("buffered lhu dispatch ready", dispatch0_ready, 1'b1);
	    t3g_load1_pdest = dut.dispatch0_pdest_w;
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check1("T3S lhu capture has no early request",
	              mem_req_valid, 1'b0);
	    tb_check1("T3S lhu reservation capture pending",
	              dut.mem_issue_res_capture_w, 1'b1);
	    `TB_TICK(clk);
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

	    // T3G 正向覆盖：在首条 load 返回前放入真实依赖者。MEM response 拍只
	    // formal-WB；沿上写 PRF/ready sticky，依赖者下一拍从 regs_q 发射。
	    set_dispatch0(32'h8000_2608,
	                  make_alu_ctrl(`OP1_SEL_RS1, `OP2_SEL_IMM,
	                                `ALU_OP_ADD, 1'b1, 1'b0, 1'b1),
	                  5'd15, 5'd0, 5'd17, 64'd1);
	    #1;
	    tb_check1("load-use dependent dispatch ready", dispatch0_ready, 1'b1);
	    t3g_dependent_pdest = dut.dispatch0_pdest_w;
	    `TB_TICK(clk);
	    clear_dispatch();
	    #1;
	    tb_check32("load-use dependent remains resident",
	               {28'b0, issue_count}, 32'd1);
	    tb_check1("load-use dependent waits before response",
	              dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);

	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_1234_5678;
		    mem_rsp_error = 1'b0;
		    #1;
		    tb_check1("buffer seed rsp ready", mem_rsp_ready, 1'b1);
		    tb_check1("buffer seed has no commit on formal WB",
		              commit0_valid, 1'b0);
	    tb_check1("load MEM formal WB0 valid", dut.wb0_valid_w, 1'b1);
	    tb_check32("load MEM formal WB0 pdest",
	               {26'b0, dut.wb0_pdest_w},
	               {26'b0, t3g_load0_pdest});
	    tb_check64("load MEM formal WB0 data", dut.wb0_data_w,
	               64'h0000_0000_1234_5678);
	    tb_check1("load-use does not select on response",
	              dut.issue0_valid_w || dut.issue1_valid_w, 1'b0);
	    $display("[T3M-RED-OBS] mem-N formal0=%0b pdest=%0d issue={%0b,%0b}",
	             dut.wb0_valid_w, dut.wb0_pdest_w,
	             dut.issue0_valid_w, dut.issue1_valid_w);
	    `TB_TICK(clk);
		    mem_rsp_valid = 1'b0;
		    #1;
		    tb_check1("buffer seed commits from ROB Q", commit0_valid, 1'b1);
		    tb_check64("buffer seed commit data from ROB Q",
		               commit0_data, 64'h0000_0000_1234_5678);
		    tb_check1("load-use selects after sticky edge", dut.issue0_valid_w, 1'b1);
	    tb_check32("load-use selected PC after sticky edge",
	               dut.issue0_pc_w[31:0], 32'h8000_2608);
	    tb_check32("load-use source tag is load pdest",
	               {26'b0, dut.issue0_src1_preg_w},
	               {26'b0, t3g_load0_pdest});
	    tb_check64("load-use source data reads stored PRF",
	               dut.issue0_src1_data_w, 64'h0000_0000_1234_5678);
	    $display("[T3G-COVERAGE-OBS] mem-N+1 issue0_pc=0x%08h preg=%0d stored=0x%016h",
	             dut.issue0_pc_w[31:0], dut.issue0_src1_preg_w,
	             dut.issue0_src1_data_w);
	    // 把 dependent add 推进 EX；下一拍与第二条 load response 形成 EX0+MEM1。
	    `TB_TICK(clk);
	    #1;

	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_0000_1800;
		    mem_rsp_error = 1'b0;
		    #1;
		    tb_check1("buffered lhu rsp ready", mem_rsp_ready, 1'b1);
		    tb_check1("mixed EX/MEM has no commit0 on formal WB",
		              commit0_valid, 1'b0);
		    tb_check1("mixed EX/MEM has no commit1 on formal WB",
		              commit1_valid, 1'b0);
	    // dependent add 此拍占 formal WB0；第二条 load 自然落 formal WB1。
	    tb_check1("dependent EX formal WB0 valid", dut.wb0_valid_w, 1'b1);
	    tb_check32("dependent EX formal WB0 pdest",
	               {26'b0, dut.wb0_pdest_w},
	               {26'b0, t3g_dependent_pdest});
	    tb_check64("dependent EX formal WB0 data", dut.wb0_data_w,
	               64'h0000_0000_1234_5679);
	    tb_check1("buffered lhu formal WB1 valid", dut.wb1_valid_w, 1'b1);
	    tb_check32("buffered lhu formal WB1 pdest",
	               {26'b0, dut.wb1_pdest_w},
	               {26'b0, t3g_load1_pdest});
	    tb_check64("buffered lhu formal WB1 data", dut.wb1_data_w,
	               64'h0000_0000_0000_1800);
	    $display("[T3M-COVERAGE-OBS] mixed ex-formal0={%0b,%0d,0x%016h} mem-formal1={%0b,%0d,0x%016h}",
	             dut.wb0_valid_w, dut.wb0_pdest_w, dut.wb0_data_w,
	             dut.wb1_valid_w, dut.wb1_pdest_w, dut.wb1_data_w);
		    `TB_TICK(clk);
		    mem_rsp_valid = 1'b0;
		    #1;
		    tb_check1("buffered lhu commits from ROB Q",
		              commit0_valid, 1'b1);
		    tb_check64("buffered lhu commit data from ROB Q",
		               commit0_data, 64'h0000_0000_0000_1800);
		    tb_check1("dependent commits beside lhu from ROB Q",
		              commit1_valid, 1'b1);
		    tb_check64("dependent commit data beside lhu",
		               commit1_data, 64'h0000_0000_1234_5679);
		    `TB_TICK(clk);
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
	    tb_check1("T3S store capture has no early request",
	              mem_req_valid, 1'b0);
	    tb_check1("T3S store reservation capture pending",
	              dut.mem_issue_res_capture_w, 1'b1);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("store starts memory request", mem_req_valid, 1'b1);
	    tb_check1("store request is write", mem_req_write, 1'b1);
	    tb_check32("store request addr", mem_req_addr, 32'h0000_0200);
	    tb_check1("store first request is probe", mem_req_probe, 1'b1);

	    // Accept probe, then return a distinct PA.  Probe success must fill SQ
	    // without consuming formal WB or making the ROB entry committable.
	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b1;
	    mem_rsp_rdata = 64'h0000_0000_8000_0200;
	    mem_rsp_error = 1'b0;
	    #1;
	    tb_check1("store probe success ready", mem_rsp_ready, 1'b1);
	    tb_check1("store probe success has no WB", dut.mem_wb_fire_w, 1'b0);
	    tb_check1("store probe success has no commit", commit0_valid, 1'b0);
	    `TB_TICK(clk);
	    mem_rsp_valid = 1'b0;
	    mem_rsp_rdata = {`XLEN{1'b0}};
	    #1;
	    tb_check1("store physical request visible", mem_req_valid, 1'b1);
	    tb_check1("store physical request write", mem_req_write, 1'b1);
	    tb_check64("store physical request uses PA", mem_req_addr,
	               64'h0000_0000_8000_0200);
	    tb_check1("store physical request pretrans", mem_req_pretrans, 1'b1);
	    tb_check1("store physical request nokill", mem_req_nokill, 1'b1);
	    tb_check1("store physical request not probe", mem_req_probe, 1'b0);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("store physical request at-most-once", mem_req_valid, 1'b0);
	    tb_check1("store cannot commit before B", commit0_valid, 1'b0);
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
		    $display("[V8G-MEM-CREDIT-BOUND] stable exact-open response completes on the cycle after both WB ports were occupied PASS");
		    tb_check1("store has no commit on response/formal-WB",
		              commit0_valid, 1'b0);
		    tb_check1("younger ALU cannot pass incomplete store",
		              commit1_valid, 1'b0);

		    `TB_TICK(clk);
		    mem_rsp_valid = 1'b0;
		    #1;
		    tb_check1("store commits from ROB Q", commit0_valid, 1'b1);
		    tb_check1("first ALU commits beside store from ROB Q",
		              commit1_valid, 1'b1);
		    tb_check1("store has no rd write", commit0_rd_en, 1'b0);
		    tb_check64("first ALU data beside delayed store",
		               commit1_data, 64'd21);

		    `TB_TICK(clk);
		    #1;
		    tb_check1("second ALU commits after delayed store pair",
		              commit0_valid, 1'b1);
		    tb_check64("second ALU data after delayed store pair",
		               commit0_data, 64'd22);

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
    // R3 capability steering：较年轻 store 取得 Universal/memory reservation，
    // 较老 simple ALU 同拍改走物理 ALU terminal。仍只有一个 LSU owner；store
    // 必须先原子捕获 reservation，下一拍才可产生唯一 probe request。
    tb_check32("alu+store pair queued", {28'b0, issue_count}, 32'd2);
    `TB_TICK(clk);
    #1;
    tb_check32("R3 ALU+store both leave IQ", {28'b0, issue_count}, 32'd0);
    tb_check1("R3 older ALU executes on ALU terminal", execute1_valid, 1'b1);
    tb_check1("R3 older ALU formal WB1 visible", dut.wb1_valid_w, 1'b1);
    tb_check64("R3 older ALU formal WB1 data",
               dut.wb1_data_w, 64'h0000_0000_0000_0055);
    tb_check1("R3 younger store captured exactly-once reservation",
              dut.mem_issue_res_valid_q, 1'b1);
    tb_check1("R3 ALU has no commit on formal WB", commit0_valid, 1'b0);
    wait_mem0_request("R3 younger store", 1'b1, 32'h0000_0100,
                      1'b0, {`XLEN{1'b0}}, 1'b0, {`STRB_W{1'b0}});
    tb_check1("R3 younger store first request is probe", mem_req_probe, 1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("R3 request consumes reservation once",
              dut.mem_issue_res_valid_q, 1'b0);
    tb_check1("R3 older ALU commits from ROB Q", commit0_valid, 1'b1);
    tb_check64("R3 older ALU commit data from ROB Q",
               commit0_data, 64'h0000_0000_0000_0055);
    `TB_TICK(clk);
    #1;
    tb_check1("R3 older ALU commits exactly once", commit0_valid, 1'b0);
    complete_sq_store_after_probe("R3 younger store",
                                  64'h0000_0000_0000_0100,
                                  64'h0000_0000_8000_0100,
                                  1'b1, 1'b0);
    tb_check32("R3 younger store rob drains", {27'b0, rob_count}, 32'd0);
    tb_check32("R3 younger store iq drains", {28'b0, issue_count}, 32'd0);
    tb_check32("R3 younger store freelist recovers", {25'b0, free_count}, 32'd32);

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
    `TB_TICK(clk);
    #1;
    complete_mem0_response("lr.d", 64'h1111_2222_3333_4444,
                           1'b1, 1'b1, 1'b1,
                           64'h1111_2222_3333_4444);

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
    tb_check1("T3S sc.d fail reservation capture pending",
              dut.mem_issue_res_capture_w, 1'b1);
    `TB_TICK(clk);
    #1;
    tb_check1("T3S sc.d fail station still has no memory write",
              mem_req_valid, 1'b0);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("sc.d fail formal WB visible", dut.wb0_valid_w, 1'b1);
	    tb_check64("sc.d fail formal status is one", dut.wb0_data_w, 64'd1);
	    tb_check1("sc.d fail has no commit on formal WB",
	              commit0_valid, 1'b0);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("sc.d fail commits from ROB Q", commit0_valid, 1'b1);
	    tb_check64("sc.d fail returns one from ROB Q", commit0_data, 64'd1);
	    `TB_TICK(clk);
	    #1;
	    tb_check1("sc.d fail commits exactly once", commit0_valid, 1'b0);

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

    run_t3s_mem_issue_reservation_contract();
    run_t3s_mem_issue_age_liveness();
    run_t3v_mem_buffer_selective_kill_contract();
    run_s2_g1_effective_kill_response_contract();
    run_s2_g1_amo_restore_and_grant_contract();
`ifndef OOO_ASSERT
    run_s2_g1_empty_miq_stale_drain_contract();
`endif
    run_t3v_miq_full_pop_parent_backpressure_contract();
    run_t3v_lrsc_width_and_exception_contract();
    run_r3_alu_terminal_no_lsu_contract();
    run_r3p1_swapped_mmio_atomic_contract();
    run_r3p1_divu_eight_younger_contract();
`endif
`endif

    run_v8p_pair_matrix_contract();
`endif

    // T3P 后 memory/AMO 不再是 lane1 可达类别；IQ focused 用例已覆盖
    // “跳过复杂项选择年轻 simple、复杂项随后晋升 lane0”，下方所有真实访存
    // 场景继续从 lane0 request/MIQ owner 路径验证完整功能。

    // V9O C0 combinational projection: emulate an edge-old queue-head
    // pregrant and a simultaneously available younger branch-resolve packet.
    // The pregrant must dominate every production consumer without requiring
    // a clock edge or starting ROB walk.
    reset_dut();
    force dut.control_event_pregrant_w = 1'b1;
    force dut.control_full_flush_barrier_w = 1'b1;
    force dut.control_full_flush_reason_w = `REDIR_REASON_TRAP;
    force dut.branch_resolve_authorized_w = 1'b1;
    force dut.branch_resolve_payload_pc_w = 64'h0000_0000_8000_b000;
    force dut.branch_resolve_payload_next_pc_w = 64'h0000_0000_8000_c000;
    force dut.branch_resolve_payload_misaligned_w = 1'b0;
    force dut.branch_resolve_payload_rob_idx_w = 4'd7;
    force dut.branch_resolve_payload_mispredict_w = 1'b1;
    force dut.branch_resolve_payload_is_branch_w = 1'b1;
    force dut.branch_resolve_payload_taken_w = 1'b1;
    force dut.branch_resolve_payload_pred_taken_w = 1'b0;
    force dut.branch_resolve_payload_bht_idx_w =
        {`BPU_BHT_INDEX_W{1'b1}};
    #1;
    tb_check1("V9O C0 exposes queue-head barrier",
              control_full_flush_barrier, 1'b1);
    tb_check32("V9O C0 exposes typed TRAP reason",
               {{(32-`REDIR_REASON_W){1'b0}}, control_full_flush_reason},
               {{(32-`REDIR_REASON_W){1'b0}}, `REDIR_REASON_TRAP});
    tb_check1("V9O C0 suppresses younger branch event",
              branch_resolve_valid, 1'b0);
    tb_check1("V9O C0 suppresses younger branch recovery",
              branch_resolve_mispredict, 1'b0);
    tb_check1("V9O C0 does not start ROB walk",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    tb_check1("V9O C0 closes dispatch lane0", dispatch0_ready, 1'b0);
    tb_check1("V9O C0 closes dispatch lane1", dispatch1_ready, 1'b0);
    tb_check1("V9O C0 emits no memory lane0 request", mem_req_valid, 1'b0);
    tb_check1("V9O C0 emits no memory lane1 request", mem1_req_valid, 1'b0);
    tb_check1("V9O C0 withholds memory lane0 response credit",
              mem_rsp_ready, 1'b0);
    tb_check1("V9O C0 withholds memory lane1 response credit",
              mem1_rsp_ready, 1'b0);
    release dut.control_event_pregrant_w;
    release dut.control_full_flush_barrier_w;
    release dut.control_full_flush_reason_w;
    release dut.branch_resolve_authorized_w;
    release dut.branch_resolve_payload_pc_w;
    release dut.branch_resolve_payload_next_pc_w;
    release dut.branch_resolve_payload_misaligned_w;
    release dut.branch_resolve_payload_rob_idx_w;
    release dut.branch_resolve_payload_mispredict_w;
    release dut.branch_resolve_payload_is_branch_w;
    release dut.branch_resolve_payload_taken_w;
    release dut.branch_resolve_payload_pred_taken_w;
    release dut.branch_resolve_payload_bht_idx_w;
    $display("[V9O-BACKEND-C0-BARRIER] younger branch/dispatch/memory actions held PASS");

    // Distinct pending-system CSR commit case: it is an older control event
    // with backend action NONE, so it must suppress the younger branch
    // production packet without asserting the full-flush barrier.
    reset_dut();
    force dut.control_event_pregrant_w = 1'b1;
    force dut.control_full_flush_barrier_w = 1'b0;
    force dut.branch_resolve_authorized_w = 1'b1;
    force dut.branch_resolve_payload_pc_w = 64'h0000_0000_8000_d000;
    force dut.branch_resolve_payload_next_pc_w =
        64'h0000_0000_8000_e000;
    force dut.branch_resolve_payload_misaligned_w = 1'b0;
    force dut.branch_resolve_payload_rob_idx_w = 4'd9;
    force dut.branch_resolve_payload_mispredict_w = 1'b1;
    force dut.branch_resolve_payload_is_branch_w = 1'b1;
    force dut.branch_resolve_payload_taken_w = 1'b1;
    force dut.branch_resolve_payload_pred_taken_w = 1'b0;
    force dut.branch_resolve_payload_bht_idx_w =
        {`BPU_BHT_INDEX_W{1'b1}};
    #1;
    tb_check1("V9O pending CSR pregrant is not a full-flush barrier",
              control_full_flush_barrier, 1'b0);
    tb_check1("V9O pending CSR pregrant suppresses younger branch event",
              branch_resolve_valid, 1'b0);
    tb_check1("V9O pending CSR pregrant suppresses younger branch recovery",
              branch_resolve_mispredict, 1'b0);
    tb_check1("V9O pending CSR pregrant does not start ROB walk",
              dut.u_dispatch_backend.rob_kill_valid_w, 1'b0);
    release dut.control_event_pregrant_w;
    release dut.control_full_flush_barrier_w;
    release dut.branch_resolve_authorized_w;
    release dut.branch_resolve_payload_pc_w;
    release dut.branch_resolve_payload_next_pc_w;
    release dut.branch_resolve_payload_misaligned_w;
    release dut.branch_resolve_payload_rob_idx_w;
    release dut.branch_resolve_payload_mispredict_w;
    release dut.branch_resolve_payload_is_branch_w;
    release dut.branch_resolve_payload_taken_w;
    release dut.branch_resolve_payload_pred_taken_w;
    release dut.branch_resolve_payload_bht_idx_w;
    $display("[V9O-PENDING-CSR-BRANCH-PRIORITY] older action-NONE commit suppresses younger branch PASS");

`ifdef HIST_SER_QH_YOUNGER_STORE_FOCUSED
        tb_finish("tb_ooo_int_backend_hist_ser_qh_younger_store");
`elsif V11R_INT_LANE1_PACKET_FOCUSED
        tb_finish("tb_ooo_int_backend_v11r_int_lane1_packet");
`elsif V11Q_INT_LANE0_PACKET_FOCUSED
        tb_finish("tb_ooo_int_backend_v11q_int_lane0_packet");
`elsif V11P_CHECKPOINT_IRREVOCABLE_WRITE_FOCUSED
        tb_finish("tb_ooo_int_backend_v11p_checkpoint_irrevocable_write");
`elsif V11O_MEMORY_BUFFER_TOKEN_FOCUSED
        tb_finish("tb_ooo_int_backend_v11o_memory_buffer_token");
`elsif V11N_MEMORY_PENDING_HOLDER_FOCUSED
        tb_finish("tb_ooo_int_backend_v11n_memory_pending_holder");
`elsif V11M_MEMORY_RESERVATION_HOLDER_FOCUSED
        tb_finish("tb_ooo_int_backend_v11m_memory_reservation_holder");
`elsif V11L_MEMORY_RETRY_HOLDER_FOCUSED
        tb_finish("tb_ooo_int_backend_v11l_memory_retry_holder");
`elsif V9R_SQ_RETRY_C0_FOCUSED
        tb_finish("tb_ooo_int_backend_v9r_sq_retry_c0");
`elsif V11I_TERMINAL_LIFECYCLE_FOCUSED
        tb_finish("tb_ooo_int_backend_v11i_terminal_lifecycle");
`elsif V8Y_SPECULATION_RECOVERY_FOCUSED
        tb_finish("tb_ooo_int_backend_v8y_speculation_recovery");
`elsif V8X_BACKEND_BRIDGE_RECOVERY_FOCUSED
        tb_finish("tb_ooo_int_backend_v8x_backend_bridge_recovery");
`elsif V8W_MAKE_TARGET
        tb_finish("tb_ooo_int_backend_v8w_memory_recovery");
`else
	    tb_finish("tb_ooo_int_backend");
`endif
  end
endmodule
