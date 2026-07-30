`include "define.v"

// v8v focused LQ test: dual allocation, full ProducerId ownership, final-PA
// disposition, dual formal completion/retirement, wrap-safe selective recovery
// and fired-load drain tombstones.
module tb_ooo_load_queue;
  `include "tb_common.svh"

  localparam ENTRY_N = 4;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PRODUCER_ID_W = ROB_INDEX_W + `OOO_PRODUCER_GEN_W;
  localparam COUNT_W = $clog2(ENTRY_N + 1);

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
  wire release0_ready;
  wire release0_q_ready;
  wire release0_fire;
  wire release1_ready;
  wire release1_q_ready;
  wire release1_fire;
  wire [(1 << PRODUCER_ID_W)-1:0] producer_live_mask;
  wire [COUNT_W-1:0] count;

  function automatic [PRODUCER_ID_W-1:0] make_pid;
    input [`OOO_PRODUCER_GEN_W-1:0] generation;
    input [ROB_INDEX_W-1:0] rob;
    begin
      make_pid = {generation, rob};
    end
  endfunction

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

  task automatic reset_dut;
    begin
      clear_events();
      rst = 1'b1;
      repeat (2) `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  task automatic alloc_pair;
    input [PRODUCER_ID_W-1:0] pid0;
    input [PRODUCER_ID_W-1:0] pid1;
    begin
      alloc0_valid = 1'b1;
      alloc0_rob = pid0[ROB_INDEX_W-1:0];
      alloc0_pid = pid0;
      alloc1_valid = 1'b1;
      alloc1_rob = pid1[ROB_INDEX_W-1:0];
      alloc1_pid = pid1;
      tb_check1("dual LQ allocation must see two edge-old credits",
                alloc0_ready && alloc1_ready, 1'b1);
      `TB_TICK(clk);
      clear_events();
      #1;
    end
  endtask

  // V11H pre-fix discriminator.  The public LQ contract permits a normal
  // memory-owner terminal before formal completion while retaining ROB
  // residency.  A later recovery must not create a killed tombstone for an
  // owner whose exact terminal has already occurred.
  task automatic run_v11h_prior_terminal_recovery_repro;
    reg [PRODUCER_ID_W-1:0] pid;
    begin
      reset_dut();
      pid = {{`OOO_PRODUCER_GEN_W{1'b1}}, 4'h2};

      alloc0_valid = 1'b1;
      alloc0_rob = pid[ROB_INDEX_W-1:0];
      alloc0_pid = pid;
      #1;
      tb_check1("V11H repro allocation has edge-old credit",
                alloc0_ready, 1'b1);
      `TB_TICK(clk);
      clear_events();

      launch0_valid = 1'b1;
      launch0_pid = pid;
      `TB_TICK(clk);
      clear_events();

      terminal0_valid = 1'b1;
      terminal0_pid = pid;
      `TB_TICK(clk);
      clear_events();
      #1;
      tb_check1("V11H normal terminal retains retire residency",
                count == 1 && producer_live_mask[pid], 1'b1);

      flush_valid = 1'b1;
      flush_all = 1'b1;
      `TB_TICK(clk);
      clear_events();
      #1;
      if ((count !== 0) || (producer_live_mask[pid] !== 1'b0)) begin
        tb_errors = tb_errors + 1;
        $display("[V11H-LQ-PRIOR-TERMINAL-RECOVERY][FAIL] count=%0d live=%b killed=%b",
                 count, producer_live_mask[pid], dut.killed_q[0]);
      end else begin
        $display("[V11H-LQ-PRIOR-TERMINAL-RECOVERY] prior_terminal=1 recovery_clear=1 ghost=0 PASS");
      end
    end
  endtask

  reg [PRODUCER_ID_W-1:0] p0;
  reg [PRODUCER_ID_W-1:0] p1;
  reg [PRODUCER_ID_W-1:0] p2;
  reg [PRODUCER_ID_W-1:0] p3;
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

    reset_dut();
    if ($test$plusargs("V11H_PRIOR_TERMINAL_REPRO_ONLY")) begin
      run_v11h_prior_terminal_recovery_repro();
      tb_finish("tb_ooo_load_queue_v11h_prior_terminal_recovery");
    end

    p0 = make_pid(4'h1, 4'h0);
    p1 = make_pid(4'h1, 4'h1);
    alloc_pair(p0, p1);
    tb_check1("dual dispatch must create two LQ residents",
              count == 2, 1'b1);
    tb_check1("LQ residents contribute complete ProducerId live bits",
              producer_live_mask[p0] && producer_live_mask[p1], 1'b1);

    issue0_valid = 1'b1;
    issue0_pid = p0;
    issue1_valid = 1'b1;
    issue1_pid = p1;
    #1;
    tb_check1("both exact dispatched loads are issue-open",
              issue0_open && issue1_open, 1'b1);
    issue0_pid = make_pid(4'h2, 4'h0);
    #1;
    tb_check1("same ROB index with stale generation is issue-closed",
              !issue0_open, 1'b1);
    clear_events();

    launch0_valid = 1'b1;
    launch0_pid = p0;
    launch1_valid = 1'b1;
    launch1_pid = p1;
    `TB_TICK(clk);
    clear_events();

    query0_valid = 1'b1;
    query0_pid = p0;
    query0_paddr = 64'h0000_0000_8000_1000;
    query1_valid = 1'b1;
    query1_pid = p0;
    query1_paddr = 64'h0000_0000_8000_1000;
    #1;
    tb_check1("same-PID dual query fails closed on both ports",
              !query0_open && !query1_open, 1'b1);
    clear_events();
    $display("[V8V-LQ-DUAL-QUERY-CONFLICT] same_pid_fail_closed=1 PASS");

    query0_valid = 1'b1;
    query0_pid = p0;
    query0_paddr = 64'h0000_0000_8000_1000;
    query0_update = 1'b1;
    query0_allow = 1'b1;
    query1_valid = 1'b1;
    query1_pid = p1;
    query1_paddr = 64'h0000_0000_8000_2000;
    query1_update = 1'b1;
    query1_replay = 1'b1;
    #1;
    tb_check1("dual final-PA queries independently match live LQ entries",
              query0_open && query1_open, 1'b1);
    `TB_TICK(clk);
    clear_events();

    response0_valid = 1'b1;
    response0_pid = p0;
    response1_valid = 1'b1;
    response1_pid = p1;
    #1;
    tb_check1("allow opens response while replay stays ordered-closed",
              response0_open && !response1_open, 1'b1);
    response1_fault = 1'b1;
    #1;
    tb_check1("precise fault keeps exact ownership without PA allow",
              response1_open, 1'b1);
    clear_events();

    query1_valid = 1'b1;
    query1_pid = p1;
    query1_paddr = 64'h0000_0000_8000_2008;
    #1;
    tb_check1("retry with changed final PA fails closed",
              !query1_open, 1'b1);
    clear_events();

    terminal0_valid = 1'b1;
    terminal0_pid = p0;
    terminal1_valid = 1'b1;
    terminal1_pid = p1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check1("normal transport terminal retains retire-resident entries",
              count == 2 && producer_live_mask[p0] &&
              producer_live_mask[p1], 1'b1);

    release0_valid = 1'b1;
    release0_pid = p0;
    release0_commit = 1'b1;
    #1;
    tb_check1("retirement before formal completion is backpressured",
              !release0_ready && !release0_fire, 1'b1);
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check1("premature retirement cannot drop the LQ entry",
              count == 2 && producer_live_mask[p0], 1'b1);

    completion0_valid = 1'b1;
    completion0_pid = p0;
    completion1_valid = 1'b1;
    completion1_pid = p1;
    release0_valid = 1'b1;
    release0_pid = p0;
    release0_commit = 1'b1;
    release1_valid = 1'b1;
    release1_pid = p1;
    release1_commit = 1'b1;
    #1;
    tb_check1("dual completion-to-retire bypass releases both exact PIDs",
              release0_ready && release1_ready, 1'b1);
    tb_check1("V9O pregrant view excludes current completion bypass",
              !release0_q_ready && !release1_q_ready, 1'b1);
    tb_check1("dual release fire is lossless",
              release0_fire && release1_fire, 1'b1);
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check1("normal WB/retire releases both LQ entries",
              count == 0, 1'b1);
    $display("[V8V-LQ-DUAL-LIFECYCLE] alloc/issue/query/replay/completion/retire PASS");

    reset_dut();
    p0 = make_pid(4'h2, 4'he);
    p1 = make_pid(4'h2, 4'hf);
    p2 = make_pid(4'h3, 4'h0);
    p3 = make_pid(4'h3, 4'h1);
    alloc_pair(p0, p1);
    alloc_pair(p2, p3);
    tb_check1("four residents exert real LQ capacity backpressure",
              count == ENTRY_N && !alloc0_ready && !alloc1_ready, 1'b1);

    launch0_valid = 1'b1;
    launch0_pid = p2;
    `TB_TICK(clk);
    clear_events();
    flush_valid = 1'b1;
    flush_all = 1'b0;
    flush_rob_head = 4'he;
    flush_boundary_rob = 4'hf;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check1("selective recovery clears unlaunched younger load only",
              count == 3, 1'b1);
    issue0_valid = 1'b1;
    issue0_pid = p2;
    #1;
    tb_check1("launched younger load remains issue-closed tombstone",
              !issue0_open, 1'b1);
    clear_events();
    terminal0_valid = 1'b1;
    terminal0_pid = p2;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check1("exact terminal releases killed tombstone",
              count == 2 && !producer_live_mask[p2], 1'b1);
    $display("[V8V-LQ-WRAP-RECOVERY] wrap-age/unlaunched-drop/fired-drain PASS");

    completion0_valid = 1'b1;
    completion0_pid = p0;
    completion1_valid = 1'b1;
    completion1_pid = p1;
    `TB_TICK(clk);
    clear_events();
    release0_valid = 1'b1;
    release0_pid = p0;
    release0_commit = 1'b1;
    release1_valid = 1'b1;
    release1_pid = p1;
    release1_commit = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check1("surviving prefix retires exactly once", count == 0, 1'b1);

    tb_finish("tb_ooo_load_queue");
  end
endmodule
