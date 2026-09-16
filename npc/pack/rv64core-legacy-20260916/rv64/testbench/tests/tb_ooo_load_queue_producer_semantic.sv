`include "define.v"

// V11H source-bound LoadQueue holder proof.
//
// The expected four-entry state is owned entirely by this testbench and is
// updated only from directed stimulus and the documented edge priority.  DUT
// lookup outputs and raw arrays are observations, never model inputs.
module tb_ooo_load_queue_producer_semantic;
  `include "tb_common.svh"

  localparam integer ENTRY_N = 4;
  localparam integer ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam integer PRODUCER_ID_W =
      ROB_INDEX_W + `OOO_PRODUCER_GEN_W;
  localparam integer COUNT_W = $clog2(ENTRY_N + 1);
  localparam integer PRODUCER_COUNT = (1 << PRODUCER_ID_W);

  reg clk;
  reg rst;

  reg flush_valid;
  reg flush_all;
  reg [ROB_INDEX_W-1:0] flush_rob_head;
  reg [ROB_INDEX_W-1:0] flush_boundary_rob;

  reg alloc0_valid;
  reg [ROB_INDEX_W-1:0] alloc0_rob;
  reg [PRODUCER_ID_W-1:0] alloc0_pid;
  reg alloc1_valid;
  reg [ROB_INDEX_W-1:0] alloc1_rob;
  reg [PRODUCER_ID_W-1:0] alloc1_pid;

  reg issue0_valid;
  reg [PRODUCER_ID_W-1:0] issue0_pid;
  reg issue1_valid;
  reg [PRODUCER_ID_W-1:0] issue1_pid;

  reg launch0_valid;
  reg [PRODUCER_ID_W-1:0] launch0_pid;
  reg launch1_valid;
  reg [PRODUCER_ID_W-1:0] launch1_pid;

  reg query0_valid;
  reg [PRODUCER_ID_W-1:0] query0_pid;
  reg [`XLEN-1:0] query0_paddr;
  reg query0_attr_valid;
  reg [1:0] query0_class;
  reg [`STRB_W-1:0] query0_strb;
  reg query0_update;
  reg query0_allow;
  reg query0_forward;
  reg query0_replay;
  reg query1_valid;
  reg [PRODUCER_ID_W-1:0] query1_pid;
  reg [`XLEN-1:0] query1_paddr;
  reg query1_attr_valid;
  reg [1:0] query1_class;
  reg [`STRB_W-1:0] query1_strb;
  reg query1_update;
  reg query1_allow;
  reg query1_forward;
  reg query1_replay;

  reg response0_valid;
  reg [PRODUCER_ID_W-1:0] response0_pid;
  reg response0_fault;
  reg response1_valid;
  reg [PRODUCER_ID_W-1:0] response1_pid;
  reg response1_fault;

  reg completion0_valid;
  reg [PRODUCER_ID_W-1:0] completion0_pid;
  reg completion1_valid;
  reg [PRODUCER_ID_W-1:0] completion1_pid;

  reg terminal0_valid;
  reg [PRODUCER_ID_W-1:0] terminal0_pid;
  reg terminal1_valid;
  reg [PRODUCER_ID_W-1:0] terminal1_pid;

  reg release0_valid;
  reg [PRODUCER_ID_W-1:0] release0_pid;
  reg release0_commit;
  reg release1_valid;
  reg [PRODUCER_ID_W-1:0] release1_pid;
  reg release1_commit;

  wire alloc0_ready;
  wire alloc1_ready;
  wire issue0_open;
  wire issue1_open;
  wire query0_open;
  wire query1_open;
  wire response0_open;
  wire response1_open;
  wire release0_q_ready;
  wire release0_ready;
  wire release0_fire;
  wire release1_q_ready;
  wire release1_ready;
  wire release1_fire;
  wire [PRODUCER_COUNT-1:0] producer_live_mask;
  wire [COUNT_W-1:0] count;

  OooLoadQueue #(
    .ENTRY_N(ENTRY_N),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .ENTRY_COUNT_W(COUNT_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(flush_valid),
    .flush_all_i(flush_all),
    .flush_rob_head_i(flush_rob_head),
    .flush_boundary_rob_i(flush_boundary_rob),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_rob_idx_i(alloc0_rob),
    .alloc0_producer_id_i(alloc0_pid),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_rob_idx_i(alloc1_rob),
    .alloc1_producer_id_i(alloc1_pid),
    .issue0_valid_i(issue0_valid),
    .issue0_producer_id_i(issue0_pid),
    .issue0_open_o(issue0_open),
    .issue1_valid_i(issue1_valid),
    .issue1_producer_id_i(issue1_pid),
    .issue1_open_o(issue1_open),
    .launch0_valid_i(launch0_valid),
    .launch0_producer_id_i(launch0_pid),
    .launch1_valid_i(launch1_valid),
    .launch1_producer_id_i(launch1_pid),
    .query0_valid_i(query0_valid),
    .query0_producer_id_i(query0_pid),
    .query0_paddr_i(query0_paddr),
    .query0_attr_valid_i(query0_attr_valid),
    .query0_class_i(query0_class),
    .query0_strb_i(query0_strb),
    .query0_open_o(query0_open),
    .query0_update_i(query0_update),
    .query0_allow_i(query0_allow),
    .query0_forward_i(query0_forward),
    .query0_replay_i(query0_replay),
    .query1_valid_i(query1_valid),
    .query1_producer_id_i(query1_pid),
    .query1_paddr_i(query1_paddr),
    .query1_attr_valid_i(query1_attr_valid),
    .query1_class_i(query1_class),
    .query1_strb_i(query1_strb),
    .query1_open_o(query1_open),
    .query1_update_i(query1_update),
    .query1_allow_i(query1_allow),
    .query1_forward_i(query1_forward),
    .query1_replay_i(query1_replay),
    .response0_valid_i(response0_valid),
    .response0_producer_id_i(response0_pid),
    .response0_fault_i(response0_fault),
    .response0_open_o(response0_open),
    .response1_valid_i(response1_valid),
    .response1_producer_id_i(response1_pid),
    .response1_fault_i(response1_fault),
    .response1_open_o(response1_open),
    .completion0_valid_i(completion0_valid),
    .completion0_producer_id_i(completion0_pid),
    .completion1_valid_i(completion1_valid),
    .completion1_producer_id_i(completion1_pid),
    .terminal0_valid_i(terminal0_valid),
    .terminal0_producer_id_i(terminal0_pid),
    .terminal1_valid_i(terminal1_valid),
    .terminal1_producer_id_i(terminal1_pid),
    .release0_valid_i(release0_valid),
    .release0_producer_id_i(release0_pid),
    .release0_commit_i(release0_commit),
    .release0_q_ready_o(release0_q_ready),
    .release0_ready_o(release0_ready),
    .release0_fire_o(release0_fire),
    .release1_valid_i(release1_valid),
    .release1_producer_id_i(release1_pid),
    .release1_commit_i(release1_commit),
    .release1_q_ready_o(release1_q_ready),
    .release1_ready_o(release1_ready),
    .release1_fire_o(release1_fire),
    .producer_live_mask_o(producer_live_mask),
    .count_o(count)
  );

  reg expected_valid [0:ENTRY_N-1];
  reg expected_launched [0:ENTRY_N-1];
  reg expected_pa_valid [0:ENTRY_N-1];
  reg expected_ordered [0:ENTRY_N-1];
  reg expected_completed [0:ENTRY_N-1];
  reg expected_killed [0:ENTRY_N-1];
  reg expected_terminal_seen [0:ENTRY_N-1];
  reg [ROB_INDEX_W-1:0] expected_rob [0:ENTRY_N-1];
  reg [PRODUCER_ID_W-1:0] expected_pid [0:ENTRY_N-1];
  reg [`XLEN-1:0] expected_paddr [0:ENTRY_N-1];
  reg expected_attr_valid [0:ENTRY_N-1];
  reg [1:0] expected_class [0:ENTRY_N-1];
  reg [`STRB_W-1:0] expected_strb [0:ENTRY_N-1];
  integer model_i;

  function automatic [PRODUCER_ID_W-1:0] make_pid;
    input [31:0] generation_seed;
    input [ROB_INDEX_W-1:0] rob;
    integer bit_i;
    reg [PRODUCER_ID_W-1:0] value;
    begin
      value = {PRODUCER_ID_W{1'b0}};
      value[ROB_INDEX_W-1:0] = rob;
      for (bit_i = 0; bit_i < `OOO_PRODUCER_GEN_W;
           bit_i = bit_i + 1)
        value[ROB_INDEX_W + bit_i] = generation_seed[bit_i];
      make_pid = value;
    end
  endfunction

  function automatic [PRODUCER_ID_W-1:0] other_generation;
    input [PRODUCER_ID_W-1:0] pid;
    reg [PRODUCER_ID_W-1:0] value;
    begin
      value = pid;
      value[ROB_INDEX_W] = !value[ROB_INDEX_W];
      other_generation = value;
    end
  endfunction

  function automatic [ROB_INDEX_W-1:0] model_rob_dist;
    input [ROB_INDEX_W-1:0] idx;
    input [ROB_INDEX_W-1:0] head;
    begin
      model_rob_dist = idx - head;
    end
  endfunction

  function automatic integer model_index;
    input [PRODUCER_ID_W-1:0] pid;
    integer idx;
    begin
      model_index = -1;
      for (idx = 0; idx < ENTRY_N; idx = idx + 1)
        if (expected_valid[idx] && (expected_pid[idx] == pid))
          model_index = idx;
    end
  endfunction

  task automatic oracle_fail;
    input [1023:0] label;
    begin
      $display("[V11H-LQ-PRODUCER-ORACLE][FAIL] %0s", label);
      $fatal(1);
    end
  endtask

  task automatic clear_events;
    begin
      flush_valid = 1'b0;
      flush_all = 1'b0;
      alloc0_valid = 1'b0;
      alloc1_valid = 1'b0;
      issue0_valid = 1'b0;
      issue1_valid = 1'b0;
      launch0_valid = 1'b0;
      launch1_valid = 1'b0;
      query0_valid = 1'b0;
      query0_update = 1'b0;
      query0_allow = 1'b0;
      query0_forward = 1'b0;
      query0_replay = 1'b0;
      query1_valid = 1'b0;
      query1_update = 1'b0;
      query1_allow = 1'b0;
      query1_forward = 1'b0;
      query1_replay = 1'b0;
      response0_valid = 1'b0;
      response0_fault = 1'b0;
      response1_valid = 1'b0;
      response1_fault = 1'b0;
      completion0_valid = 1'b0;
      completion1_valid = 1'b0;
      terminal0_valid = 1'b0;
      terminal1_valid = 1'b0;
      release0_valid = 1'b0;
      release0_commit = 1'b0;
      release1_valid = 1'b0;
      release1_commit = 1'b0;
    end
  endtask

  task automatic model_clear_entry;
    input integer idx;
    begin
      expected_valid[idx] = 1'b0;
      expected_launched[idx] = 1'b0;
      expected_pa_valid[idx] = 1'b0;
      expected_ordered[idx] = 1'b0;
      expected_completed[idx] = 1'b0;
      expected_killed[idx] = 1'b0;
      expected_terminal_seen[idx] = 1'b0;
      expected_rob[idx] = {ROB_INDEX_W{1'b0}};
      expected_pid[idx] = {PRODUCER_ID_W{1'b0}};
      expected_paddr[idx] = {`XLEN{1'b0}};
      expected_attr_valid[idx] = 1'b0;
      expected_class[idx] = `OOO_MEM_CLASS_RSVD;
      expected_strb[idx] = {`STRB_W{1'b0}};
    end
  endtask

  task automatic model_clear;
    begin
      for (model_i = 0; model_i < ENTRY_N; model_i = model_i + 1)
        model_clear_entry(model_i);
    end
  endtask

  task automatic check_raw_state;
    input [1023:0] label;
    integer idx;
    integer expected_count;
    reg [PRODUCER_COUNT-1:0] expected_mask;
    begin
      expected_count = 0;
      expected_mask = {PRODUCER_COUNT{1'b0}};
      for (idx = 0; idx < ENTRY_N; idx = idx + 1) begin
        if (expected_valid[idx]) begin
          expected_count = expected_count + 1;
          expected_mask[expected_pid[idx]] = 1'b1;
        end
        if (dut.valid_q[idx] !== expected_valid[idx])
          oracle_fail({label, " raw valid"});
        if (dut.launched_q[idx] !== expected_launched[idx])
          oracle_fail({label, " raw launched"});
        if (dut.pa_valid_q[idx] !== expected_pa_valid[idx])
          oracle_fail({label, " raw pa_valid"});
        if (dut.ordered_q[idx] !== expected_ordered[idx])
          oracle_fail({label, " raw ordered"});
        if (dut.completed_q[idx] !== expected_completed[idx])
          oracle_fail({label, " raw completed"});
        if (dut.killed_q[idx] !== expected_killed[idx])
          oracle_fail({label, " raw killed"});
        if (dut.terminal_seen_q[idx] !== expected_terminal_seen[idx])
          oracle_fail({label, " raw terminal_seen"});
        if (expected_valid[idx]) begin
          if (^dut.producer_id_q[idx] === 1'bx)
            oracle_fail({label, " raw ProducerId unknown"});
          if (dut.producer_id_q[idx] !== expected_pid[idx])
            oracle_fail({label, " raw ProducerId mismatch"});
          if (dut.rob_idx_q[idx] !== expected_rob[idx])
            oracle_fail({label, " raw ROB index mismatch"});
          if (expected_pa_valid[idx]) begin
            if ((dut.paddr_q[idx] !== expected_paddr[idx]) ||
                (dut.attr_valid_q[idx] !== expected_attr_valid[idx]) ||
                (dut.class_q[idx] !== expected_class[idx]) ||
                (dut.strb_q[idx] !== expected_strb[idx]))
              oracle_fail({label, " raw final-PA metadata mismatch"});
          end
        end
      end
      if (count !== expected_count[COUNT_W-1:0])
        oracle_fail({label, " count mismatch"});
      if (producer_live_mask !== expected_mask)
        oracle_fail({label, " producer live mask mismatch"});
    end
  endtask

  task automatic model_allocate_one;
    input integer idx;
    input [PRODUCER_ID_W-1:0] pid;
    begin
      expected_valid[idx] = 1'b1;
      expected_launched[idx] = 1'b0;
      expected_pa_valid[idx] = 1'b0;
      expected_ordered[idx] = 1'b0;
      expected_completed[idx] = 1'b0;
      expected_killed[idx] = 1'b0;
      expected_terminal_seen[idx] = 1'b0;
      expected_rob[idx] = pid[ROB_INDEX_W-1:0];
      expected_pid[idx] = pid;
      expected_paddr[idx] = {`XLEN{1'b0}};
      expected_attr_valid[idx] = 1'b0;
      expected_class[idx] = `OOO_MEM_CLASS_RSVD;
      expected_strb[idx] = {`STRB_W{1'b0}};
    end
  endtask

  task automatic model_allocate;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    input dual;
    integer idx;
    integer idx0;
    integer idx1;
    begin
      idx0 = -1;
      idx1 = -1;
      for (idx = 0; idx < ENTRY_N; idx = idx + 1) begin
        if (!expected_valid[idx] && (idx0 < 0))
          idx0 = idx;
        else if (!expected_valid[idx] && (idx1 < 0))
          idx1 = idx;
      end
      if ((idx0 < 0) || (dual && (idx1 < 0)))
        oracle_fail("model allocation lacked edge-old slot");
      model_allocate_one(idx0, pid0);
      if (dual)
        model_allocate_one(idx1, pid1);
    end
  endtask

  task automatic drive_allocate;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    input dual;
    begin
      alloc0_valid = 1'b1;
      alloc0_rob = pid0[ROB_INDEX_W-1:0];
      alloc0_pid = pid0;
      alloc1_valid = dual;
      alloc1_rob = pid1[ROB_INDEX_W-1:0];
      alloc1_pid = pid1;
      #1;
      if (alloc0_ready !== 1'b1)
        oracle_fail("accepted allocation lane0 lacked credit");
      if (dual && (alloc1_ready !== 1'b1))
        oracle_fail("accepted allocation lane1 lacked credit");
      `TB_TICK(clk);
      clear_events();
      model_allocate(pid0, pid1, dual);
      #1;
      check_raw_state("post allocation");
    end
  endtask

  task automatic model_launch;
    input [PRODUCER_ID_W-1:0] pid;
    integer idx;
    begin
      idx = model_index(pid);
      if (idx < 0)
        oracle_fail("model launch missed ProducerId");
      expected_launched[idx] = 1'b1;
    end
  endtask

  task automatic drive_launch_pair;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    input dual;
    begin
      launch0_valid = 1'b1;
      launch0_pid = pid0;
      launch1_valid = dual;
      launch1_pid = pid1;
      `TB_TICK(clk);
      clear_events();
      model_launch(pid0);
      if (dual)
        model_launch(pid1);
      #1;
      check_raw_state("post launch");
    end
  endtask

  task automatic model_query;
    input [PRODUCER_ID_W-1:0] pid;
    input [`XLEN-1:0] paddr;
    input allow;
    input forward;
    input replay;
    integer idx;
    begin
      idx = model_index(pid);
      if (idx < 0)
        oracle_fail("model query missed ProducerId");
      expected_pa_valid[idx] = 1'b1;
      expected_paddr[idx] = paddr;
      expected_attr_valid[idx] = 1'b1;
      expected_class[idx] = `OOO_MEM_CLASS_CACHED;
      expected_strb[idx] = {`STRB_W{1'b1}};
      expected_ordered[idx] = !replay && (allow || forward);
    end
  endtask

  task automatic drive_query_pair;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    input [`XLEN-1:0] paddr0;
    input [`XLEN-1:0] paddr1;
    input replay1;
    begin
      query0_valid = 1'b1;
      query0_pid = pid0;
      query0_paddr = paddr0;
      query0_attr_valid = 1'b1;
      query0_class = `OOO_MEM_CLASS_CACHED;
      query0_strb = {`STRB_W{1'b1}};
      query0_update = 1'b1;
      query0_allow = 1'b1;
      query1_valid = 1'b1;
      query1_pid = pid1;
      query1_paddr = paddr1;
      query1_attr_valid = 1'b1;
      query1_class = `OOO_MEM_CLASS_CACHED;
      query1_strb = {`STRB_W{1'b1}};
      query1_update = 1'b1;
      query1_allow = !replay1;
      query1_replay = replay1;
      #1;
      if ((query0_open !== 1'b1) || (query1_open !== 1'b1))
        oracle_fail("exact dual query did not open");
      `TB_TICK(clk);
      clear_events();
      model_query(pid0, paddr0, 1'b1, 1'b0, 1'b0);
      model_query(pid1, paddr1, !replay1, 1'b0, replay1);
      #1;
      check_raw_state("post query");
    end
  endtask

  task automatic model_completion;
    input [PRODUCER_ID_W-1:0] pid;
    integer idx;
    begin
      idx = model_index(pid);
      if (idx >= 0)
        expected_completed[idx] = 1'b1;
    end
  endtask

  task automatic model_terminal;
    input [PRODUCER_ID_W-1:0] pid;
    integer idx;
    begin
      idx = model_index(pid);
      if (idx < 0)
        oracle_fail("model terminal missed ProducerId");
      if (expected_killed[idx])
        model_clear_entry(idx);
      else
        expected_terminal_seen[idx] = 1'b1;
    end
  endtask

  task automatic model_release;
    input [PRODUCER_ID_W-1:0] pid;
    integer idx;
    begin
      idx = model_index(pid);
      if (idx < 0)
        oracle_fail("model release missed ProducerId");
      model_clear_entry(idx);
    end
  endtask

  task automatic model_recover;
    input all_entries;
    input [ROB_INDEX_W-1:0] head;
    input [ROB_INDEX_W-1:0] boundary;
    integer idx;
    reg target;
    begin
      for (idx = 0; idx < ENTRY_N; idx = idx + 1) begin
        target = expected_valid[idx] &&
            (all_entries ||
             (model_rob_dist(expected_rob[idx], head) >
              model_rob_dist(boundary, head)));
        if (target) begin
          if (expected_launched[idx] && !expected_completed[idx] &&
              !expected_terminal_seen[idx]) begin
            expected_launched[idx] = 1'b1;
            expected_completed[idx] = 1'b0;
            expected_killed[idx] = 1'b1;
            expected_terminal_seen[idx] = 1'b0;
          end else begin
            model_clear_entry(idx);
          end
        end
      end
    end
  endtask

  task automatic drive_recovery;
    input all_entries;
    input [ROB_INDEX_W-1:0] head;
    input [ROB_INDEX_W-1:0] boundary;
    begin
      flush_valid = 1'b1;
      flush_all = all_entries;
      flush_rob_head = head;
      flush_boundary_rob = boundary;
      `TB_TICK(clk);
      clear_events();
      model_recover(all_entries, head, boundary);
      #1;
      check_raw_state("post recovery");
    end
  endtask

  task automatic reset_dut;
    begin
      clear_events();
      rst = 1'b1;
      repeat (2) `TB_TICK(clk);
      rst = 1'b0;
      model_clear();
      #1;
      check_raw_state("reset");
    end
  endtask

  task automatic run_mutation_only_negative_events;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    begin
      launch0_valid = 1'b1;
      launch0_pid = other_generation(pid0);
      launch1_valid = 1'b1;
      launch1_pid = other_generation(pid1);
      `TB_TICK(clk);
      clear_events();
      #1;
      check_raw_state("wrong-generation launch");

      completion0_valid = 1'b1;
      completion0_pid = other_generation(pid0);
      completion1_valid = 1'b1;
      completion1_pid = other_generation(pid1);
      `TB_TICK(clk);
      clear_events();
      #1;
      check_raw_state("wrong-generation completion");

      terminal0_valid = 1'b1;
      terminal0_pid = other_generation(pid0);
      terminal1_valid = 1'b1;
      terminal1_pid = other_generation(pid1);
      `TB_TICK(clk);
      clear_events();
      #1;
      check_raw_state("wrong-generation terminal");
    end
  endtask

  reg [PRODUCER_ID_W-1:0] pid0;
  reg [PRODUCER_ID_W-1:0] pid1;
  reg [PRODUCER_ID_W-1:0] pid2;
  reg [PRODUCER_ID_W-1:0] pid3;
  reg [PRODUCER_ID_W-1:0] pid4;
  reg [PRODUCER_ID_W-1:0] pid5;
  reg [PRODUCER_ID_W-1:0] pid6;
  reg [PRODUCER_ID_W-1:0] pid7;
  reg [PRODUCER_ID_W-1:0] pid8;
  reg [PRODUCER_ID_W-1:0] wrap0;
  reg [PRODUCER_ID_W-1:0] wrap1;
  reg [PRODUCER_ID_W-1:0] wrap2;
  reg [PRODUCER_ID_W-1:0] wrap3;
  reg [PRODUCER_ID_W-1:0] same0;
  reg [PRODUCER_ID_W-1:0] same1;
  reg [PRODUCER_ID_W-1:0] same2;

  initial begin
    clk = 1'b0;
    rst = 1'b0;
    tb_errors = 0;
    flush_rob_head = {ROB_INDEX_W{1'b0}};
    flush_boundary_rob = {ROB_INDEX_W{1'b0}};
    alloc0_rob = {ROB_INDEX_W{1'b0}};
    alloc1_rob = {ROB_INDEX_W{1'b0}};
    alloc0_pid = {PRODUCER_ID_W{1'b0}};
    alloc1_pid = {PRODUCER_ID_W{1'b0}};
    issue0_pid = {PRODUCER_ID_W{1'b0}};
    issue1_pid = {PRODUCER_ID_W{1'b0}};
    launch0_pid = {PRODUCER_ID_W{1'b0}};
    launch1_pid = {PRODUCER_ID_W{1'b0}};
    query0_pid = {PRODUCER_ID_W{1'b0}};
    query0_paddr = {`XLEN{1'b0}};
    query0_attr_valid = 1'b1;
    query0_class = `OOO_MEM_CLASS_CACHED;
    query0_strb = {`STRB_W{1'b1}};
    query1_pid = {PRODUCER_ID_W{1'b0}};
    query1_paddr = {`XLEN{1'b0}};
    query1_attr_valid = 1'b1;
    query1_class = `OOO_MEM_CLASS_CACHED;
    query1_strb = {`STRB_W{1'b1}};
    response0_pid = {PRODUCER_ID_W{1'b0}};
    response1_pid = {PRODUCER_ID_W{1'b0}};
    completion0_pid = {PRODUCER_ID_W{1'b0}};
    completion1_pid = {PRODUCER_ID_W{1'b0}};
    terminal0_pid = {PRODUCER_ID_W{1'b0}};
    terminal1_pid = {PRODUCER_ID_W{1'b0}};
    release0_pid = {PRODUCER_ID_W{1'b0}};
    release1_pid = {PRODUCER_ID_W{1'b0}};
    clear_events();

    pid0 = make_pid(32'h1, 4'h2);
    pid1 = make_pid(32'h2, 4'h3);
    pid2 = make_pid(32'h3, 4'h4);
    pid3 = make_pid(32'h4, 4'h5);
    pid4 = make_pid(32'h5, 4'h6);
    pid5 = make_pid(32'h6, 4'h7);
    pid6 = make_pid(32'h7, 4'h8);
    pid7 = make_pid(32'h8, 4'h9);
    pid8 = make_pid(32'h9, 4'ha);

    if ($test$plusargs("V11H_PID_KNOWN_ASSERTION_PROBE")) begin
      reset_dut();
      alloc0_valid = 1'b1;
      alloc0_rob = 4'h2;
      alloc0_pid = make_pid(32'h1, 4'h2);
      alloc0_pid[PRODUCER_ID_W-1:ROB_INDEX_W] =
          {`OOO_PRODUCER_GEN_W{1'bx}};
      `TB_TICK(clk);
      clear_events();
      `TB_TICK(clk);
      $display("[V11H-LQ-PID-KNOWN-PROBE][FAIL] raw-Q assertion did not fire");
      $fatal;
    end

    reset_dut();
    drive_allocate(pid0, pid1, 1'b1);

    issue0_valid = 1'b1;
    issue0_pid = other_generation(pid0);
    issue1_valid = 1'b1;
    issue1_pid = other_generation(pid1);
    #1;
    if (issue0_open || issue1_open)
      oracle_fail("wrong-generation issue lookup opened");
    clear_events();

    query0_valid = 1'b1;
    query0_pid = other_generation(pid0);
    query1_valid = 1'b1;
    query1_pid = other_generation(pid1);
    #1;
    if (query0_open || query1_open)
      oracle_fail("wrong-generation query lookup opened");
    clear_events();

    response0_valid = 1'b1;
    response0_pid = other_generation(pid0);
    response0_fault = 1'b1;
    response1_valid = 1'b1;
    response1_pid = other_generation(pid1);
    response1_fault = 1'b1;
    #1;
    if (response0_open || response1_open)
      oracle_fail("wrong-generation response lookup opened");
    clear_events();

    if ($test$plusargs("V11H_MUTATION_NEGATIVE"))
      run_mutation_only_negative_events(pid0, pid1);

    issue0_valid = 1'b1;
    issue0_pid = pid0;
    issue1_valid = 1'b1;
    issue1_pid = pid1;
    #1;
    if (!issue0_open || !issue1_open)
      oracle_fail("exact issue lookup remained closed");
    clear_events();

    drive_launch_pair(pid0, pid1, 1'b1);

    query0_valid = 1'b1;
    query0_pid = other_generation(pid0);
    query1_valid = 1'b1;
    query1_pid = other_generation(pid1);
    #1;
    if (query0_open || query1_open)
      oracle_fail("launched wrong-generation query lookup opened");
    clear_events();

    response0_valid = 1'b1;
    response0_pid = other_generation(pid0);
    response0_fault = 1'b1;
    response1_valid = 1'b1;
    response1_pid = other_generation(pid1);
    response1_fault = 1'b1;
    #1;
    if (response0_open || response1_open)
      oracle_fail("launched wrong-generation response lookup opened");
    clear_events();

    query0_valid = 1'b1;
    query0_pid = pid0;
    query0_paddr = 64'h0000_0000_8000_0200;
    query1_valid = 1'b1;
    query1_pid = pid0;
    query1_paddr = 64'h0000_0000_8000_0200;
    #1;
    if (query0_open || query1_open)
      oracle_fail("same-PID dual query opened");
    clear_events();

    drive_query_pair(
        pid0, pid1,
        64'h0000_0000_8000_0200,
        64'h0000_0000_8000_0300,
        1'b1);

    response0_valid = 1'b1;
    response0_pid = pid0;
    response1_valid = 1'b1;
    response1_pid = pid1;
    #1;
    if (!response0_open || response1_open)
      oracle_fail("allow/replay response authorization mismatch");
    response1_fault = 1'b1;
    #1;
    if (!response1_open)
      oracle_fail("fault response did not bypass ordered state");
    clear_events();
    $display("[V11H-LQ-BIRTH-CAM] GEN_W=%0d dual/full-P/query/response PASS",
             `OOO_PRODUCER_GEN_W);

    terminal0_valid = 1'b1;
    terminal0_pid = pid0;
    `TB_TICK(clk);
    clear_events();
    model_terminal(pid0);
    #1;
    check_raw_state("normal terminal");

    issue0_valid = 1'b1;
    issue0_pid = pid0;
    query0_valid = 1'b1;
    query0_pid = pid0;
    query0_paddr = 64'h0000_0000_8000_0200;
    response0_valid = 1'b1;
    response0_pid = pid0;
    response0_fault = 1'b1;
    #1;
    if (issue0_open || query0_open || response0_open)
      oracle_fail("terminal-seen entry reopened a physical operation");
    clear_events();

    release0_valid = 1'b1;
    release0_pid = pid0;
    release0_commit = 1'b1;
    #1;
    if (release0_ready || release0_fire)
      oracle_fail("release before formal completion opened");
    clear_events();

    drive_recovery(1'b1, 4'h0, 4'h0);
    terminal0_valid = 1'b1;
    terminal0_pid = pid1;
    `TB_TICK(clk);
    clear_events();
    model_terminal(pid1);
    #1;
    check_raw_state("killed terminal drain");
    $display("[V11H-LQ-TERMINAL-RECOVERY] GEN_W=%0d prior-terminal-clear/killed-drain PASS",
             `OOO_PRODUCER_GEN_W);

    drive_allocate(pid2, pid3, 1'b1);
    drive_launch_pair(pid2, pid3, 1'b1);
    drive_query_pair(
        pid2, pid3,
        64'h0000_0000_8000_0400,
        64'h0000_0000_8000_0500,
        1'b0);
    terminal0_valid = 1'b1;
    terminal0_pid = pid2;
    terminal1_valid = 1'b1;
    terminal1_pid = pid3;
    `TB_TICK(clk);
    clear_events();
    model_terminal(pid2);
    model_terminal(pid3);
    #1;
    check_raw_state("dual normal terminal");

    completion0_valid = 1'b1;
    completion0_pid = pid2;
    completion1_valid = 1'b1;
    completion1_pid = pid3;
    `TB_TICK(clk);
    clear_events();
    model_completion(pid2);
    model_completion(pid3);
    #1;
    check_raw_state("dual completion");

    release0_valid = 1'b1;
    release0_pid = other_generation(pid2);
    release1_valid = 1'b1;
    release1_pid = other_generation(pid3);
    #1;
    if (release0_ready || release1_ready)
      oracle_fail("wrong-generation release opened");
    release0_pid = pid2;
    release0_commit = 1'b1;
    release1_pid = pid3;
    release1_commit = 1'b1;
    #1;
    if (!release0_q_ready || !release1_q_ready ||
        !release0_ready || !release1_ready ||
        !release0_fire || !release1_fire)
      oracle_fail("exact dual release did not fire");
    `TB_TICK(clk);
    clear_events();
    model_release(pid2);
    model_release(pid3);
    #1;
    check_raw_state("dual release");

    drive_allocate(pid4, pid5, 1'b1);
    completion0_valid = 1'b1;
    completion0_pid = pid4;
    `TB_TICK(clk);
    clear_events();
    model_completion(pid4);
    #1;
    check_raw_state("single completion");
    drive_allocate(pid6, pid7, 1'b1);

    alloc0_valid = 1'b1;
    alloc0_rob = pid8[ROB_INDEX_W-1:0];
    alloc0_pid = pid8;
    #1;
    if (alloc0_ready)
      oracle_fail("full queue exposed allocation credit");

    release0_valid = 1'b1;
    release0_pid = pid4;
    release0_commit = 1'b1;
    #1;
    if (!release0_ready || !release0_fire)
      oracle_fail("full queue exact release did not fire");
    if (alloc0_ready)
      oracle_fail("full queue borrowed same-edge release slot");
    `TB_TICK(clk);
    clear_events();
    model_release(pid4);
    #1;
    check_raw_state("full plus release");
    drive_allocate(pid8, {PRODUCER_ID_W{1'b0}}, 1'b0);
    $display("[V11H-LQ-RETIRE-REUSE] GEN_W=%0d completion/release/no-borrow/reuse PASS",
             `OOO_PRODUCER_GEN_W);

    wrap0 = make_pid(32'ha, 4'he);
    wrap1 = make_pid(32'hb, 4'hf);
    wrap2 = make_pid(32'hc, 4'h0);
    wrap3 = make_pid(32'hd, 4'h1);
    reset_dut();
    drive_allocate(wrap0, wrap1, 1'b1);
    drive_allocate(wrap2, wrap3, 1'b1);
    drive_launch_pair(wrap2, {PRODUCER_ID_W{1'b0}}, 1'b0);
    drive_recovery(1'b0, 4'he, 4'hf);
    terminal0_valid = 1'b1;
    terminal0_pid = wrap2;
    `TB_TICK(clk);
    clear_events();
    model_terminal(wrap2);
    #1;
    check_raw_state("wrap killed terminal");
    drive_recovery(1'b1, 4'he, 4'hf);

    same0 = make_pid(32'he, 4'hb);
    same1 = make_pid(32'hf, 4'hc);
    same2 = make_pid(32'h3, 4'hd);

    drive_allocate(same0, {PRODUCER_ID_W{1'b0}}, 1'b0);
    launch0_valid = 1'b1;
    launch0_pid = same0;
    flush_valid = 1'b1;
    flush_all = 1'b1;
    `TB_TICK(clk);
    clear_events();
    model_launch(same0);
    model_recover(1'b1, 4'h0, 4'h0);
    #1;
    check_raw_state("same-edge launch recovery");
    terminal0_valid = 1'b1;
    terminal0_pid = same0;
    `TB_TICK(clk);
    clear_events();
    model_terminal(same0);
    #1;
    check_raw_state("same-edge launch tombstone drain");

    drive_allocate(same1, {PRODUCER_ID_W{1'b0}}, 1'b0);
    drive_launch_pair(same1, {PRODUCER_ID_W{1'b0}}, 1'b0);
    completion0_valid = 1'b1;
    completion0_pid = same1;
    flush_valid = 1'b1;
    flush_all = 1'b1;
    `TB_TICK(clk);
    clear_events();
    model_completion(same1);
    model_recover(1'b1, 4'h0, 4'h0);
    #1;
    check_raw_state("same-edge completion recovery");

    drive_allocate(same2, {PRODUCER_ID_W{1'b0}}, 1'b0);
    drive_launch_pair(same2, {PRODUCER_ID_W{1'b0}}, 1'b0);
    terminal0_valid = 1'b1;
    terminal0_pid = same2;
    flush_valid = 1'b1;
    flush_all = 1'b1;
    `TB_TICK(clk);
    clear_events();
    model_terminal(same2);
    model_recover(1'b1, 4'h0, 4'h0);
    #1;
    check_raw_state("same-edge terminal recovery");

    $display("[V11H-LQ-RECOVERY-PRIORITY] GEN_W=%0d wrap/launch/completion/terminal PASS",
             `OOO_PRODUCER_GEN_W);
    $display("[V11H-LQ-ALL] GEN_W=%0d stimulus-owned raw-Q model PASS",
             `OOO_PRODUCER_GEN_W);
    tb_finish("tb_ooo_load_queue_producer_semantic");
  end
endmodule
