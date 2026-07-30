`timescale 1ns/1ps

// V11D：用独立沿前状态模型核对 memory-owner token 游标。
//
// expected token 只由 stimulus、model_live/model_pid_live 与 model_cursor
// 推导；不得读取 DUT token 后再构造参考状态。hierarchical cursor 仅作诊断，
// ready/token 黑盒比较与后续分配序列才是游标语义 oracle。
module tb_ooo_mem_owner_tracker_cursor #(
  parameter TOKEN_COUNT = 4,
  parameter TOKEN_W = 2,
  parameter COUNT_W = 3,
  parameter PRODUCER_ID_W = 8,
  parameter PRODUCER_COUNT = (1 << PRODUCER_ID_W)
);
  localparam [1:0] OWNER_KIND_STORE = 2'b01;
  localparam [1:0] OWNER_KIND_RESERVED = 2'b11;

  reg clk;
  reg rst;
  reg alloc0_valid;
  reg [1:0] alloc0_kind;
  reg [1:0] alloc0_epoch;
  reg [PRODUCER_ID_W-1:0] alloc0_producer_id;
  wire alloc0_ready;
  wire [TOKEN_W-1:0] alloc0_token;
  reg alloc1_valid;
  reg [1:0] alloc1_kind;
  reg [1:0] alloc1_epoch;
  reg [PRODUCER_ID_W-1:0] alloc1_producer_id;
  wire alloc1_ready;
  wire [TOKEN_W-1:0] alloc1_token;
  reg alloc_pair_atomic;
  reg free0_valid;
  reg [1:0] free0_kind;
  reg [TOKEN_W-1:0] free0_token;
  reg [1:0] free0_epoch;
  wire free0_ready;
  reg free1_valid;
  reg [1:0] free1_kind;
  reg [TOKEN_W-1:0] free1_token;
  reg [1:0] free1_epoch;
  wire free1_ready;
  reg [TOKEN_COUNT-1:0] release_mask;
  wire [TOKEN_COUNT-1:0] live_mask;
  wire [TOKEN_COUNT*2-1:0] kind_table;
  wire [TOKEN_COUNT*2-1:0] epoch_table;
  wire [TOKEN_COUNT*PRODUCER_ID_W-1:0] producer_id_table;
  wire [PRODUCER_COUNT-1:0] producer_live_mask;
  wire [COUNT_W-1:0] live_count;

  reg [TOKEN_COUNT-1:0] model_live;
  reg [PRODUCER_COUNT-1:0] model_pid_live;
  reg [1:0] model_kind [0:TOKEN_COUNT-1];
  reg [1:0] model_epoch [0:TOKEN_COUNT-1];
  reg [PRODUCER_ID_W-1:0] model_pid [0:TOKEN_COUNT-1];
  reg [TOKEN_W-1:0] model_cursor;
  integer model_i;
  integer fill_i;
  integer next_pid;

  OooMemOwnerTracker #(
    .TOKEN_COUNT(TOKEN_COUNT),
    .TOKEN_W(TOKEN_W),
    .KIND_W(2),
    .EPOCH_W(2),
    .COUNT_W(COUNT_W),
    .PRODUCER_ID_W(PRODUCER_ID_W),
    .PRODUCER_COUNT(PRODUCER_COUNT)
  ) dut (
    .clk(clk),
    .rst(rst),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_kind_i(alloc0_kind),
    .alloc0_epoch_i(alloc0_epoch),
    .alloc0_producer_id_i(alloc0_producer_id),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_token_o(alloc0_token),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_kind_i(alloc1_kind),
    .alloc1_epoch_i(alloc1_epoch),
    .alloc1_producer_id_i(alloc1_producer_id),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_token_o(alloc1_token),
    .alloc_pair_atomic_i(alloc_pair_atomic),
    .free0_valid_i(free0_valid),
    .free0_kind_i(free0_kind),
    .free0_token_i(free0_token),
    .free0_epoch_i(free0_epoch),
    .free0_ready_o(free0_ready),
    .free1_valid_i(free1_valid),
    .free1_kind_i(free1_kind),
    .free1_token_i(free1_token),
    .free1_epoch_i(free1_epoch),
    .free1_ready_o(free1_ready),
    .release_mask_i(release_mask),
    .live_mask_o(live_mask),
    .kind_table_o(kind_table),
    .epoch_table_o(epoch_table),
    .producer_id_table_o(producer_id_table),
    .producer_live_mask_o(producer_live_mask),
    .live_count_o(live_count)
  );

  always #5 clk = ~clk;

  task automatic fail_phase;
    input [8*128-1:0] phase;
    input [8*128-1:0] detail;
    begin
      $display("[V11D-CURSOR-ORACLE][FAIL] phase=%0s detail=%0s",
               phase, detail);
      $fatal(1);
    end
  endtask

  task automatic clear_inputs;
    begin
      alloc0_valid = 1'b0;
      alloc0_kind = OWNER_KIND_STORE;
      alloc0_epoch = 2'b00;
      alloc0_producer_id = {PRODUCER_ID_W{1'b0}};
      alloc1_valid = 1'b0;
      alloc1_kind = OWNER_KIND_STORE;
      alloc1_epoch = 2'b00;
      alloc1_producer_id = {PRODUCER_ID_W{1'b0}};
      alloc_pair_atomic = 1'b0;
      free0_valid = 1'b0;
      free0_kind = 2'b00;
      free0_token = {TOKEN_W{1'b0}};
      free0_epoch = 2'b00;
      free1_valid = 1'b0;
      free1_kind = 2'b00;
      free1_token = {TOKEN_W{1'b0}};
      free1_epoch = 2'b00;
      release_mask = {TOKEN_COUNT{1'b0}};
    end
  endtask

  task automatic reset_model;
    begin
      model_live = {TOKEN_COUNT{1'b0}};
      model_pid_live = {PRODUCER_COUNT{1'b0}};
      model_cursor = {TOKEN_W{1'b0}};
      for (model_i = 0; model_i < TOKEN_COUNT; model_i = model_i + 1) begin
        model_kind[model_i] = 2'b00;
        model_epoch[model_i] = 2'b00;
        model_pid[model_i] = {PRODUCER_ID_W{1'b0}};
      end
    end
  endtask

  function automatic [TOKEN_W-1:0] token_at_offset;
    input [TOKEN_W-1:0] base;
    input integer offset;
    begin
      token_at_offset = base + offset;
    end
  endfunction

  function automatic [COUNT_W-1:0] model_popcount;
    input [TOKEN_COUNT-1:0] bits;
    integer count_i;
    begin
      model_popcount = {COUNT_W{1'b0}};
      for (count_i = 0; count_i < TOKEN_COUNT; count_i = count_i + 1)
        model_popcount = model_popcount + bits[count_i];
    end
  endfunction

  task automatic check_registered_state;
    input [8*128-1:0] phase;
    integer check_i;
    begin
      if (live_mask !== model_live)
        fail_phase(phase, "live_mask differs from independent model");
      if (producer_live_mask !== model_pid_live)
        fail_phase(phase, "producer_live_mask differs from independent model");
      if (live_count !== model_popcount(model_live))
        fail_phase(phase, "live_count differs from independent model");
      if (dut.next_token_q !== model_cursor)
        fail_phase(phase, "next_token_q differs from independent cursor");
      for (check_i = 0; check_i < TOKEN_COUNT;
           check_i = check_i + 1) begin
        if (model_live[check_i] &&
            ((kind_table[check_i*2 +: 2] !== model_kind[check_i]) ||
             (epoch_table[check_i*2 +: 2] !== model_epoch[check_i]) ||
             (producer_id_table[
                check_i*PRODUCER_ID_W +: PRODUCER_ID_W] !==
              model_pid[check_i])))
          fail_phase(phase, "live token metadata differs from model");
      end
    end
  endtask

  task automatic apply_reset;
    begin
      @(negedge clk);
      clear_inputs();
      rst = 1'b1;
      repeat (2) @(posedge clk);
      reset_model();
      #1;
      check_registered_state("reset");
      @(negedge clk);
      rst = 1'b0;
    end
  endtask

  task automatic step;
    input [8*128-1:0] phase;
    reg expected0_found;
    reg [TOKEN_W-1:0] expected0_token;
    reg expected1_found;
    reg [TOKEN_W-1:0] expected1_token;
    reg expected0_claim;
    reg expected0_ready;
    reg expected1_ready;
    reg expected_pair_present;
    reg expected_pair_commit;
    reg expected0_fire;
    reg expected1_fire;
    reg expected_free0_exact;
    reg expected_free1_exact;
    reg expected_free0_ready;
    reg expected_free1_ready;
    reg expected_free0_fire;
    reg expected_free1_fire;
    reg [TOKEN_COUNT-1:0] store_live_mask;
    reg [TOKEN_COUNT-1:0] release_effective;
    reg [TOKEN_COUNT-1:0] death_mask;
    reg [TOKEN_COUNT-1:0] birth_mask;
    reg [TOKEN_COUNT-1:0] live_next;
    reg [PRODUCER_COUNT-1:0] pid_clear_mask;
    reg [PRODUCER_COUNT-1:0] pid_set_mask;
    reg [PRODUCER_COUNT-1:0] pid_live_next;
    reg [TOKEN_W-1:0] cursor_next;
    integer scan_i;
    integer event_i;
    begin
      #1;
      expected0_found = 1'b0;
      expected0_token = model_cursor;
      for (scan_i = 0; scan_i < TOKEN_COUNT; scan_i = scan_i + 1) begin
        if (!expected0_found &&
            !model_live[token_at_offset(model_cursor, scan_i)]) begin
          expected0_found = 1'b1;
          expected0_token = token_at_offset(model_cursor, scan_i);
        end
      end

      expected0_claim = alloc0_valid && expected0_found &&
          (alloc0_kind != OWNER_KIND_RESERVED) &&
          !model_pid_live[alloc0_producer_id];
      expected1_found = 1'b0;
      expected1_token = model_cursor;
      for (scan_i = 0; scan_i < TOKEN_COUNT; scan_i = scan_i + 1) begin
        if (!expected1_found &&
            !model_live[token_at_offset(model_cursor, scan_i)] &&
            !(expected0_claim &&
              (token_at_offset(model_cursor, scan_i) ==
               expected0_token))) begin
          expected1_found = 1'b1;
          expected1_token = token_at_offset(model_cursor, scan_i);
        end
      end

      expected0_ready = expected0_found &&
          (alloc0_kind != OWNER_KIND_RESERVED) &&
          !model_pid_live[alloc0_producer_id];
      expected1_ready = expected1_found &&
          (alloc1_kind != OWNER_KIND_RESERVED) &&
          !model_pid_live[alloc1_producer_id] &&
          !(expected0_claim &&
            (alloc1_producer_id == alloc0_producer_id));
      expected_pair_present =
          alloc_pair_atomic && alloc0_valid && alloc1_valid;
      expected_pair_commit =
          expected_pair_present && expected0_ready && expected1_ready;
      expected0_fire = expected_pair_present ? expected_pair_commit :
          (alloc0_valid && expected0_ready &&
           !(alloc_pair_atomic && alloc1_valid));
      expected1_fire = expected_pair_present ? expected_pair_commit :
          (!alloc_pair_atomic && alloc1_valid && expected1_ready);

      store_live_mask = {TOKEN_COUNT{1'b0}};
      for (event_i = 0; event_i < TOKEN_COUNT;
           event_i = event_i + 1)
        if (model_live[event_i] &&
            (model_kind[event_i] == OWNER_KIND_STORE))
          store_live_mask[event_i] = 1'b1;
      release_effective = release_mask & store_live_mask;
      expected_free0_exact = model_live[free0_token] &&
          (model_kind[free0_token] == free0_kind) &&
          (model_epoch[free0_token] == free0_epoch);
      expected_free0_ready =
          expected_free0_exact && !release_effective[free0_token];
      expected_free0_fire = free0_valid && expected_free0_ready;
      expected_free1_exact = model_live[free1_token] &&
          (model_kind[free1_token] == free1_kind) &&
          (model_epoch[free1_token] == free1_epoch);
      expected_free1_ready = expected_free1_exact &&
          !release_effective[free1_token] &&
          !(expected_free0_fire && (free1_token == free0_token));
      expected_free1_fire = free1_valid && expected_free1_ready;

      if (alloc0_valid &&
          ((alloc0_ready !== expected0_ready) ||
           (alloc0_token !== expected0_token)))
        fail_phase(phase, "lane0 ready/token differs from cursor model");
      if (alloc1_valid &&
          ((alloc1_ready !== expected1_ready) ||
           (alloc1_token !== expected1_token)))
        fail_phase(phase, "lane1 ready/token differs from cursor model");
      if (free0_valid && (free0_ready !== expected_free0_ready))
        fail_phase(phase, "free0 ready differs from edge-old model");
      if (free1_valid && (free1_ready !== expected_free1_ready))
        fail_phase(phase, "free1 ready differs from edge-old model");

      death_mask = release_effective;
      if (expected_free0_fire)
        death_mask[free0_token] = 1'b1;
      if (expected_free1_fire)
        death_mask[free1_token] = 1'b1;
      birth_mask = {TOKEN_COUNT{1'b0}};
      if (expected0_fire)
        birth_mask[expected0_token] = 1'b1;
      if (expected1_fire)
        birth_mask[expected1_token] = 1'b1;
      live_next = (model_live & ~death_mask) | birth_mask;

      pid_clear_mask = {PRODUCER_COUNT{1'b0}};
      for (event_i = 0; event_i < TOKEN_COUNT;
           event_i = event_i + 1)
        if (death_mask[event_i])
          pid_clear_mask[model_pid[event_i]] = 1'b1;
      pid_set_mask = {PRODUCER_COUNT{1'b0}};
      if (expected0_fire)
        pid_set_mask[alloc0_producer_id] = 1'b1;
      if (expected1_fire)
        pid_set_mask[alloc1_producer_id] = 1'b1;
      pid_live_next =
          (model_pid_live & ~pid_clear_mask) | pid_set_mask;

      cursor_next = model_cursor;
      if (expected1_fire)
        cursor_next = expected1_token + 1'b1;
      else if (expected0_fire)
        cursor_next = expected0_token + 1'b1;

      @(posedge clk);
      if (expected0_fire) begin
        model_kind[expected0_token] = alloc0_kind;
        model_epoch[expected0_token] = alloc0_epoch;
        model_pid[expected0_token] = alloc0_producer_id;
      end
      if (expected1_fire) begin
        model_kind[expected1_token] = alloc1_kind;
        model_epoch[expected1_token] = alloc1_epoch;
        model_pid[expected1_token] = alloc1_producer_id;
      end
      model_live = live_next;
      model_pid_live = pid_live_next;
      model_cursor = cursor_next;
      #1;
      check_registered_state(phase);
    end
  endtask

  task automatic drive_dual_store;
    input integer pid0;
    input integer pid1;
    input [8*128-1:0] phase;
    begin
      @(negedge clk);
      clear_inputs();
      alloc0_valid = 1'b1;
      alloc0_kind = OWNER_KIND_STORE;
      alloc0_epoch = pid0[1:0];
      alloc0_producer_id = pid0[PRODUCER_ID_W-1:0];
      alloc1_valid = 1'b1;
      alloc1_kind = OWNER_KIND_STORE;
      alloc1_epoch = pid1[1:0];
      alloc1_producer_id = pid1[PRODUCER_ID_W-1:0];
      step(phase);
    end
  endtask

  initial begin
    if ((TOKEN_COUNT != (1 << TOKEN_W)) ||
        ((1 << COUNT_W) <= TOKEN_COUNT) ||
        ((TOKEN_COUNT != 4) && (TOKEN_COUNT != 32)))
      fail_phase("parameter-shape", "V11D supports TOKEN_COUNT=4 or 32");

    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    reset_model();
    repeat (2) @(posedge clk);
    #1;
    check_registered_state("initial-reset");
    @(negedge clk);
    rst = 1'b0;
    next_pid = 1;
    step("post-reset-idle-hold");

    // lane0-only、lane1-only、lane0 PID blocked/lane1 fire，以及
    // lane1 PID blocked/lane0 fire，分别覆盖四种 cursor advance 入口。
    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    step("lane0-only");

    @(negedge clk);
    clear_inputs();
    alloc1_valid = 1'b1;
    alloc1_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc1_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    step("lane1-only");

    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = 1;
    alloc1_valid = 1'b1;
    alloc1_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc1_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    step("lane0-pid-blocked-lane1-fire");

    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    alloc1_valid = 1'b1;
    alloc1_producer_id = 2;
    step("lane1-pid-blocked-lane0-fire");

    @(negedge clk);
    clear_inputs();
    step("idle-hold-after-lane-selection");
    $display("[V11D-CURSOR-LANE-SELECTION] token_count=%0d PASS",
             TOKEN_COUNT);

    // 从 reset 的 cursor=0 双路填满全表，再制造两个不相邻空洞。
    // 32-token 配置的第二个空洞位于 scan offset 30，可拒绝截短扫描。
    apply_reset();
    step("post-reset-idle-hold");
    next_pid = 1;
    for (fill_i = 0; fill_i < TOKEN_COUNT/2; fill_i = fill_i + 1) begin
      drive_dual_store(next_pid, next_pid + 1, "dual-fill");
      next_pid = next_pid + 2;
    end

    @(negedge clk);
    clear_inputs();
    release_mask[1] = 1'b1;
    release_mask[TOKEN_COUNT-2] = 1'b1;
    step("nonadjacent-hole-release");
    drive_dual_store(next_pid, next_pid + 1, "nonadjacent-hole-scan");
    next_pid = next_pid + 2;

    // cursor 此时位于 TOKEN_COUNT-1；释放尾/头两个 token 后的双出生
    // 必须按 N-1、0 顺序跨环，并把 cursor 推进到 1。
    @(negedge clk);
    clear_inputs();
    release_mask[TOKEN_COUNT-1] = 1'b1;
    release_mask[0] = 1'b1;
    step("tail-head-release");
    drive_dual_store(next_pid, next_pid + 1, "tail-head-wrap-dual");
    next_pid = next_pid + 2;
    $display("[V11D-CURSOR-RING-SCAN] token_count=%0d PASS",
             TOKEN_COUNT);

    // 满表同沿 exact death 不得借 token；下一沿从保持的 cursor 取回它。
    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    free0_valid = 1'b1;
    free0_token = model_cursor;
    free0_kind = model_kind[model_cursor];
    free0_epoch = model_epoch[model_cursor];
    step("exact-death-same-edge-no-reuse");

    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    step("exact-death-next-edge-reuse");

    // STORE bulk death obeys相同的沿前可见性。
    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    release_mask[model_cursor] = 1'b1;
    step("bulk-death-same-edge-no-reuse");

    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    step("bulk-death-next-edge-reuse");
    $display("[V11D-CURSOR-DEATH-VISIBILITY] token_count=%0d PASS",
             TOKEN_COUNT);

    // 单 credit 原子双 lane 只能 split-ready/zero-fire；cursor 必须保持，
    // 随后的 standalone lane0 必须取得同一个 credit。
    @(negedge clk);
    clear_inputs();
    release_mask[model_cursor] = 1'b1;
    step("atomic-credit-create");

    @(negedge clk);
    clear_inputs();
    alloc_pair_atomic = 1'b1;
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    alloc1_valid = 1'b1;
    alloc1_producer_id = next_pid + 1;
    alloc1_epoch = next_pid + 1;
    step("atomic-single-credit-zero-fire");

    @(negedge clk);
    clear_inputs();
    alloc0_valid = 1'b1;
    alloc0_producer_id = next_pid[PRODUCER_ID_W-1:0];
    alloc0_epoch = next_pid[1:0];
    next_pid = next_pid + 1;
    step("atomic-held-credit-standalone-reuse");

    // 非原子双 lane 在单 credit 下只允许 lane0 出生，cursor 由 lane0 推进。
    @(negedge clk);
    clear_inputs();
    release_mask[model_cursor] = 1'b1;
    step("nonatomic-credit-create");
    drive_dual_store(next_pid, next_pid + 1,
                     "nonatomic-single-credit-lane0-fire");
    next_pid = next_pid + 2;

    @(negedge clk);
    clear_inputs();
    step("final-idle-hold");
    $display("[V11D-CURSOR-ATOMIC-HOLD] token_count=%0d PASS",
             TOKEN_COUNT);
    $display("[PASS] tb_ooo_mem_owner_tracker_cursor");
    $finish;
  end
endmodule
