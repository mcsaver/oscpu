`include "define.v"

// MIQ 事件代数 focused TB：flush 过滤、同拍 head pop、push/kill 优先级以及
// 环形 head 非零时的压缩顺序。重点锁住 MIQ-G1：已消费 DRAIN 不得被 flush 复活。
module tb_ooo_mem_inflight_queue;
  `include "tb_common.svh"

  localparam ENTRY_N = 4;
  localparam ENTRY_W = 2;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;
  localparam PHY_REG_ADDR_W = `OOO_PHY_REG_ADDR_W;
  localparam [1:0] KIND_LOAD = 2'd0;
  localparam [1:0] KIND_PROBE = 2'd1;
  localparam [1:0] KIND_DRAIN = 2'd2;

  reg clk;
  reg rst;
  reg flush;
  reg push_valid;
  reg [1:0] push_kind;
  reg [1:0] push_owner_kind;
  reg [4:0] push_owner_token;
  reg [1:0] push_mmu_epoch;
  reg [`XLEN-1:0] push_fault_tval;
  reg [ROB_INDEX_W-1:0] push_rob;
  reg [PHY_REG_ADDR_W-1:0] push_pdest;
  reg push_pdest_fp;
  reg [1:0] push_size;
  reg push_unsigned;
  reg [`XLEN-1:0] push_addr;
  reg [`XLEN-1:0] push_wdata;
  reg [`STRB_W-1:0] push_wstrb;
  reg pop_valid;
  reg [2:0] pop_owner_mutation;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob;
  reg [ROB_INDEX_W-1:0] rob_head;

  wire head_valid;
  wire [1:0] head_kind;
  wire [1:0] head_owner_kind;
  wire [4:0] head_owner_token;
  wire [1:0] head_mmu_epoch;
  wire [`XLEN-1:0] head_fault_tval;
  wire head_effective_killed;
  wire pop_owner_match;
  wire pop_tval_echo_match;
  wire head_killed;
  wire [ROB_INDEX_W-1:0] head_rob;
  wire [PHY_REG_ADDR_W-1:0] head_pdest;
  wire head_pdest_fp;
  wire [1:0] head_size;
  wire head_unsigned;
  wire [`XLEN-1:0] head_addr;
  wire [`XLEN-1:0] head_wdata;
  wire [`STRB_W-1:0] head_wstrb;
  wire next_head_valid;
  wire [1:0] next_head_kind;
  wire [1:0] next_head_owner_kind;
  wire [4:0] next_head_owner_token;
  wire [1:0] next_head_mmu_epoch;
  wire [`XLEN-1:0] next_head_fault_tval;
  wire next_head_killed;
  wire next_head_effective_killed;
  wire [ROB_INDEX_W-1:0] next_head_rob;
  wire [ENTRY_W:0] count;
  wire empty;
  wire full;
  wire [31:0] occupancy_token_mask;
  wire [ENTRY_N-1:0] entry_valid;
  wire [ENTRY_N*2-1:0] entry_kind;
  wire [ENTRY_N*ROB_INDEX_W-1:0] entry_rob;
  wire [ENTRY_N*`XLEN-1:0] entry_addr;
  wire [1:0] pop_owner_kind = head_owner_kind ^
      ((pop_owner_mutation == 3'd1) ? 2'b01 : 2'b00);
  wire [4:0] pop_owner_token = head_owner_token ^
      ((pop_owner_mutation == 3'd2) ? 5'b00001 : 5'b00000);
  wire [1:0] pop_mmu_epoch = head_mmu_epoch ^
      ((pop_owner_mutation == 3'd3) ? 2'b01 : 2'b00);
  wire [`XLEN-1:0] pop_fault_tval = head_fault_tval ^
      ((pop_owner_mutation == 3'd4) ? {{(`XLEN-1){1'b0}}, 1'b1} :
                                       {`XLEN{1'b0}});

  OooMemInflightQueue #(
    .ENTRY_N(ENTRY_N),
    .ENTRY_W(ENTRY_W),
    .ROB_INDEX_W(ROB_INDEX_W),
    .PHY_REG_ADDR_W(PHY_REG_ADDR_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_i(flush),
    .push_valid_i(push_valid),
    .push_kind_i(push_kind),
    .push_owner_kind_i(push_owner_kind),
    .push_owner_token_i(push_owner_token),
    .push_mmu_epoch_i(push_mmu_epoch),
    .push_fault_tval_i(push_fault_tval),
    .push_rob_idx_i(push_rob),
    .push_pdest_i(push_pdest),
    .push_pdest_fp_i(push_pdest_fp),
    .push_size_i(push_size),
    .push_unsigned_i(push_unsigned),
    .push_eff_addr_i(push_addr),
    .push_wdata_i(push_wdata),
    .push_wstrb_i(push_wstrb),
    .pop_valid_i(pop_valid),
    .pop_owner_kind_i(pop_owner_kind),
    .pop_owner_token_i(pop_owner_token),
    .pop_mmu_epoch_i(pop_mmu_epoch),
    .pop_fault_tval_i(pop_fault_tval),
    .pop_owner_match_o(pop_owner_match),
    .pop_tval_echo_match_o(pop_tval_echo_match),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob),
    .rob_head_idx_i(rob_head),
    .head_valid_o(head_valid),
    .head_kind_o(head_kind),
    .head_owner_kind_o(head_owner_kind),
    .head_owner_token_o(head_owner_token),
    .head_mmu_epoch_o(head_mmu_epoch),
    .head_fault_tval_o(head_fault_tval),
    .head_killed_o(head_killed),
    .head_effective_killed_o(head_effective_killed),
    .head_rob_idx_o(head_rob),
    .head_pdest_o(head_pdest),
    .head_pdest_fp_o(head_pdest_fp),
    .head_size_o(head_size),
    .head_unsigned_o(head_unsigned),
    .head_eff_addr_o(head_addr),
    .head_wdata_o(head_wdata),
    .head_wstrb_o(head_wstrb),
    .next_head_valid_o(next_head_valid),
    .next_head_kind_o(next_head_kind),
    .next_head_owner_kind_o(next_head_owner_kind),
    .next_head_owner_token_o(next_head_owner_token),
    .next_head_mmu_epoch_o(next_head_mmu_epoch),
    .next_head_fault_tval_o(next_head_fault_tval),
    .next_head_killed_o(next_head_killed),
    .next_head_effective_killed_o(next_head_effective_killed),
    .next_head_rob_idx_o(next_head_rob),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
    .occupancy_token_mask_o(occupancy_token_mask),
    .entry_valid_o(entry_valid),
    .entry_kind_o(entry_kind),
    .entry_rob_idx_o(entry_rob),
    .entry_addr_o(entry_addr)
  );

  task automatic clear_events;
    begin
      flush = 1'b0;
      push_valid = 1'b0;
      pop_valid = 1'b0;
      pop_owner_mutation = 3'd0;
      kill_valid = 1'b0;
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

  task automatic push_one;
    input [1:0] kind;
    input [ROB_INDEX_W-1:0] rob;
    input [`XLEN-1:0] addr;
    begin
      push_kind = kind;
      push_rob = rob;
      push_addr = addr;
      push_owner_kind = (kind == KIND_LOAD) ? 2'b00 :
                        ((kind == KIND_PROBE) || (kind == KIND_DRAIN)) ?
                        2'b01 : 2'b10;
      push_owner_token = rob;
      push_mmu_epoch = rob[1:0];
      push_fault_tval = addr;
      push_valid = 1'b1;
      `TB_TICK(clk);
      push_valid = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    flush = 1'b0;
    push_valid = 1'b0;
    push_kind = KIND_LOAD;
    push_owner_kind = 2'b00;
    push_owner_token = 5'd0;
    push_mmu_epoch = 2'b00;
    push_fault_tval = {`XLEN{1'b0}};
    push_rob = {ROB_INDEX_W{1'b0}};
    push_pdest = {PHY_REG_ADDR_W{1'b0}};
    push_pdest_fp = 1'b0;
    push_size = 2'd3;
    push_unsigned = 1'b0;
    push_addr = {`XLEN{1'b0}};
    push_wdata = 64'h0123_4567_89ab_cdef;
    push_wstrb = {`STRB_W{1'b1}};
    pop_valid = 1'b0;
    pop_owner_mutation = 3'd0;
    kill_valid = 1'b0;
    kill_rob = {ROB_INDEX_W{1'b0}};
    rob_head = {ROB_INDEX_W{1'b0}};

    // MIQ-G1 主反例：唯一 DRAIN 的 response 与 flush 同拍 fire，next-state 必为空。
    reset_dut();
    push_one(KIND_DRAIN, 4'd0, 64'h8000_1000);
    flush = 1'b1;
    pop_valid = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("flush+pop single DRAIN count", {29'b0, count}, 32'd0);
    tb_check1("flush+pop single DRAIN empty", empty, 1'b1);
    tb_check1("flush+pop single DRAIN head invalid", head_valid, 1'b0);
    tb_check32("flush+pop single DRAIN no valid slot", {28'b0, entry_valid}, 32'd0);
    $display("[T4N-DRAIN-B-GLOBAL-FLUSH-POP] completed DRAIN response is removed before flush keep-set PASS");
    // 给 delayed invariant checker 一个观察沿；旧实现应在这里精确报错。
    `TB_TICK(clk);

    // flush 不带 pop：transport-irrevocable DRAIN head 必须保留，
    // LOAD 被清；head valid 不能替代实际 pop fire 作为扣除条件。
    reset_dut();
    push_one(KIND_DRAIN, 4'd1, 64'h8000_1100);
    push_one(KIND_LOAD, 4'd2, 64'h8000_1200);
    flush = 1'b1;
    kill_valid = 1'b1;
    kill_rob = 4'd0;
    #1;
    tb_check1("flush stalled DRAIN head is valid without pop",
              head_valid && !pop_valid, 1'b1);
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("flush keeps only unconsumed DRAIN", {29'b0, count}, 32'd1);
    tb_check32("flush survivor kind", {30'b0, head_kind}, {30'b0, KIND_DRAIN});
    tb_check1("flush survivor not killed", head_killed, 1'b0);
    tb_check32("flush survivor valid layout", {28'b0, entry_valid}, 32'd1);
    if (head_addr !== 64'h8000_1100) begin
      $display("[CHECK-FAIL] flush survivor addr got=0x%016h", head_addr);
      tb_errors = tb_errors + 1;
    end

    // 环形 head!=0：pop 掉第一个 DRAIN，flush 丢 LOAD，只保留后一个 DRAIN 的 payload。
    reset_dut();
    push_one(KIND_LOAD, 4'd0, 64'h8000_2000);
    pop_valid = 1'b1;
    `TB_TICK(clk);
    pop_valid = 1'b0;
    push_one(KIND_DRAIN, 4'd1, 64'h8000_2100);
    push_one(KIND_PROBE, 4'd2, 64'h8000_2200);
    push_one(KIND_DRAIN, 4'd3, 64'h8000_2300);
    flush = 1'b1;
    pop_valid = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("wrapped flush+pop survivor count", {29'b0, count}, 32'd1);
    tb_check32("wrapped flush+pop survivor kind", {30'b0, head_kind},
               {30'b0, KIND_DRAIN});
    tb_check32("wrapped flush+pop compact layout", {28'b0, entry_valid}, 32'd1);
    if (head_addr !== 64'h8000_2300) begin
      $display("[CHECK-FAIL] wrapped survivor addr got=0x%016h expected=0x0000000080002300",
               head_addr);
      tb_errors = tb_errors + 1;
    end
    $display("[MIQ-FLUSH-G1-FOCUSED] consumed_drain_removed=1 stalled_head_no_pop_preserved=1 unconsumed_drain_preserved=1 survivor_identity_match=1 wrapped_order=1 PASS");
    `TB_TICK(clk);

    // flush+pop+push+kill 全交叠：旧 head pop 生效；flush 拍 push 不接收，kill 无额外效果。
    reset_dut();
    push_one(KIND_DRAIN, 4'd1, 64'h8000_3000);
    flush = 1'b1;
    pop_valid = 1'b1;
    push_valid = 1'b1;
    push_kind = KIND_DRAIN;
    push_rob = 4'd3;
    push_addr = 64'h8000_3300;
    kill_valid = 1'b1;
    kill_rob = 4'd0;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("flush+pop+push+kill count", {29'b0, count}, 32'd0);
    tb_check1("flush+pop+push+kill empty", empty, 1'b1);
    `TB_TICK(clk);

    // 非 flush 的 pop+push 仍支持同拍守恒，新 entry 成为唯一 head。
    reset_dut();
    push_one(KIND_LOAD, 4'd1, 64'h8000_4000);
    pop_valid = 1'b1;
    push_valid = 1'b1;
    push_kind = KIND_DRAIN;
    push_rob = 4'd2;
    push_addr = 64'h8000_4200;
    push_owner_kind = 2'b01;
    push_owner_token = 5'd2;
    push_mmu_epoch = 2'b10;
    push_fault_tval = 64'h8000_4200;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("normal pop+push count", {29'b0, count}, 32'd1);
    tb_check32("normal pop+push new head kind", {30'b0, head_kind},
               {30'b0, KIND_DRAIN});
    if (head_addr !== 64'h8000_4200) begin
      $display("[CHECK-FAIL] normal pop+push head addr got=0x%016h", head_addr);
      tb_errors = tb_errors + 1;
    end

    // 同拍 push+kill 的既有 F2 语义保持：younger LOAD 入队即带 killed；随后 flush 清除。
    reset_dut();
    push_kind = KIND_LOAD;
    push_rob = 4'd3;
    push_addr = 64'h8000_5000;
    push_owner_kind = 2'b00;
    push_owner_token = 5'd3;
    push_mmu_epoch = 2'b11;
    push_fault_tval = 64'h8000_5000;
    push_valid = 1'b1;
    kill_valid = 1'b1;
    kill_rob = 4'd1;
    rob_head = 4'd0;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("same-cycle push+kill count", {29'b0, count}, 32'd1);
    tb_check1("same-cycle push+kill marks younger LOAD", head_killed, 1'b1);
    flush = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("flush clears killed LOAD", {29'b0, count}, 32'd0);

    // R4-S1-ID: the 9-bit identity is kind+token+epoch.  fault_tval remains
    // captured provenance and is checked on an independent echo path.
    reset_dut();
    push_one(KIND_PROBE, 4'd5, 64'h0000_0000_9000_5000);
    tb_check32("owner tuple kind", {30'b0, head_owner_kind}, 32'd1);
    tb_check32("owner tuple token", {27'b0, head_owner_token}, 32'd5);
    tb_check32("owner tuple epoch", {30'b0, head_mmu_epoch}, 32'd1);
    if (head_fault_tval !== 64'h0000_0000_9000_5000) begin
      $display("[CHECK-FAIL] owner fault_tval got=0x%016h", head_fault_tval);
      tb_errors = tb_errors + 1;
    end
    tb_check32("owner token MIQ occupancy mask", occupancy_token_mask, 32'h0000_0020);
    tb_check1("exact response owner match", pop_owner_match, 1'b1);
    tb_check1("exact response tval echo", pop_tval_echo_match, 1'b1);
    pop_owner_mutation = 3'd1;
    #1;
    tb_check1("wrong-kind response rejected", pop_owner_match, 1'b0);
    pop_owner_mutation = 3'd2;
    #1;
    tb_check1("wrong-token response rejected", pop_owner_match, 1'b0);
    pop_owner_mutation = 3'd3;
    #1;
    tb_check1("wrong-epoch response rejected", pop_owner_match, 1'b0);
    pop_owner_mutation = 3'd4;
    #1;
    tb_check1("tval drift is not owner identity", pop_owner_match, 1'b1);
    tb_check1("wrong-tval response caught by echo", pop_tval_echo_match, 1'b0);
    pop_owner_mutation = 3'd0;
    pop_valid = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("exact response pop count", {29'b0, count}, 32'd0);
    tb_check32("exact response clears occupancy mask", occupancy_token_mask, 32'd0);

    // Same ROB tag is not identity: two ordered candidates may reuse the same
    // ROB value while their owner tokens remain distinct.
    reset_dut();
    push_one(KIND_LOAD, 4'd6, 64'h0000_0000_9100_6000);
    push_kind = KIND_PROBE;
    push_rob = 4'd6;
    push_addr = 64'h0000_0000_9100_7000;
    push_owner_kind = 2'b01;
    push_owner_token = 5'd7;
    push_mmu_epoch = 2'b10;
    push_fault_tval = 64'h0000_0000_9100_7000;
    push_valid = 1'b1;
    `TB_TICK(clk);
    push_valid = 1'b0;
    #1;
    tb_check32("same ROB distinct owner count", {29'b0, count}, 32'd2);
    tb_check32("same ROB distinct owner mask", occupancy_token_mask, 32'h0000_00c0);
    pop_owner_mutation = 3'd2;
    #1;
    tb_check1("same ROB next-token response rejected at head", pop_owner_match, 1'b0);
    pop_owner_mutation = 3'd0;
    pop_valid = 1'b1;
    `TB_TICK(clk);
    pop_valid = 1'b0;
    #1;
    tb_check32("same ROB second owner token", {27'b0, head_owner_token}, 32'd7);
    tb_check32("same ROB second owner rob", {27'b0, head_rob}, 32'd6);
    pop_valid = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("same ROB owners both drain", {29'b0, count}, 32'd0);

    // Global flush removes killable owners from MIQ accounting but carries the
    // surviving nokill DRAIN tuple bit-for-bit.  The dropped LOAD token is not
    // released here; the bridge's later tagged drop terminal owns that release.
    reset_dut();
    push_one(KIND_LOAD, 4'd4, 64'h0000_0000_a000_4000);
    push_one(KIND_DRAIN, 4'd5, 64'h0000_0000_a000_5000);
    flush = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("flush owner survivor count", {29'b0, count}, 32'd1);
    tb_check32("flush owner survivor token", {27'b0, head_owner_token}, 32'd5);
    tb_check32("flush owner survivor kind", {30'b0, head_owner_kind}, 32'd1);
    tb_check32("flush owner survivor epoch", {30'b0, head_mmu_epoch}, 32'd1);
    tb_check32("flush owner survivor occupancy mask", occupancy_token_mask, 32'h0000_0020);
    if (head_fault_tval !== 64'h0000_0000_a000_5000) begin
      $display("[CHECK-FAIL] flush survivor fault_tval got=0x%016h", head_fault_tval);
      tb_errors = tb_errors + 1;
    end

    // A selective kill arriving with the exact response must win over the old
    // registered killed bit for side-effect gating, while exact pop still
    // consumes the owner once.
    reset_dut();
    push_one(KIND_LOAD, 4'd3, 64'h0000_0000_b000_3000);
    kill_valid = 1'b1;
    kill_rob = 4'd1;
    rob_head = 4'd0;
    pop_valid = 1'b1;
    #1;
    tb_check1("same-cycle selective kill old bit clear", head_killed, 1'b0);
    tb_check1("same-cycle selective kill effective", head_effective_killed, 1'b1);
    tb_check1("same-cycle selective kill exact owner", pop_owner_match, 1'b1);
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("same-cycle selective kill exact pop", {29'b0, count}, 32'd0);

    reset_dut();
    push_one(KIND_PROBE, 4'd3, 64'h0000_0000_b100_3000);
    kill_valid = 1'b1;
    kill_rob = 4'd1;
    rob_head = 4'd0;
    pop_valid = 1'b1;
    #1;
    tb_check1("same-cycle probe kill effective", head_effective_killed, 1'b1);
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("same-cycle probe kill exact pop", {29'b0, count}, 32'd0);

    reset_dut();
    push_one(KIND_LOAD, 4'd2, 64'h0000_0000_b200_2000);
    flush = 1'b1;
    pop_valid = 1'b1;
    #1;
    tb_check1("same-cycle global flush effective kill", head_effective_killed, 1'b1);
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("same-cycle global flush exact pop", {29'b0, count}, 32'd0);

    // LEGACY is currently the single-width AMO/LR/SC phase and therefore owns
    // an ATOMIC identity, not LOAD/STORE.
    reset_dut();
    push_one(2'd3, 4'd7, 64'h0000_0000_b300_7000);
    tb_check32("legacy phase owner kind", {30'b0, head_owner_kind}, 32'd2);
    pop_valid = 1'b1;
    `TB_TICK(clk);
    clear_events();
    #1;
    tb_check32("legacy exact owner pop", {29'b0, count}, 32'd0);

    // v8u/F4 next-head is a read-only edge-old view.  Current pop consumes A
    // only; B is visible before the edge and becomes current after it, while C
    // remains the next entry.  No second pop or synthetic ownership occurs.
    reset_dut();
    push_one(KIND_LOAD, 4'd1, 64'h0000_0000_c000_1000);
    push_one(KIND_LOAD, 4'd2, 64'h0000_0000_c000_2000);
    push_one(KIND_LOAD, 4'd3, 64'h0000_0000_c000_3000);
    tb_check1("v8u next valid with three residents", next_head_valid, 1'b1);
    tb_check32("v8u next kind B", {30'b0, next_head_kind},
               {30'b0, KIND_LOAD});
    tb_check32("v8u next owner kind B", {30'b0, next_head_owner_kind}, 32'd0);
    tb_check32("v8u next token B", {27'b0, next_head_owner_token}, 32'd2);
    tb_check32("v8u next epoch B", {30'b0, next_head_mmu_epoch}, 32'd2);
    tb_check32("v8u next ROB B", {27'b0, next_head_rob}, 32'd2);
    if (next_head_fault_tval !== 64'h0000_0000_c000_2000) begin
      $display("[CHECK-FAIL] v8u next tval B got=0x%016h",
               next_head_fault_tval);
      tb_errors = tb_errors + 1;
    end
    pop_valid = 1'b1;
    #1;
    tb_check32("v8u pre-edge next remains B", {27'b0, next_head_owner_token},
               32'd2);
    `TB_TICK(clk);
    pop_valid = 1'b0;
    #1;
    tb_check32("v8u B becomes current", {27'b0, head_owner_token}, 32'd2);
    tb_check32("v8u C becomes next", {27'b0, next_head_owner_token}, 32'd3);
    tb_check32("v8u one pop leaves two", {29'b0, count}, 32'd2);

    // Wrap the next pointer across entry 3 -> entry 0.
    push_one(KIND_LOAD, 4'd4, 64'h0000_0000_c000_4000);
    pop_valid = 1'b1;
    `TB_TICK(clk);
    pop_valid = 1'b0;
    #1;
    tb_check32("v8u current C before wrap", {27'b0, head_owner_token}, 32'd3);
    tb_check32("v8u next D before wrap", {27'b0, next_head_owner_token}, 32'd4);
    push_one(KIND_LOAD, 4'd5, 64'h0000_0000_c000_5000);
    pop_valid = 1'b1;
    `TB_TICK(clk);
    pop_valid = 1'b0;
    #1;
    tb_check32("v8u wrapped current D index3", {27'b0, head_owner_token},
               32'd4);
    tb_check32("v8u wrapped next E index0", {27'b0, next_head_owner_token},
               32'd5);

    // Same-cycle selective kill must be reflected by the next face even
    // before killed_q is updated.  It closes fast admission conservatively.
    reset_dut();
    push_one(KIND_LOAD, 4'd1, 64'h0000_0000_c100_1000);
    push_one(KIND_LOAD, 4'd3, 64'h0000_0000_c100_3000);
    kill_valid = 1'b1;
    kill_rob = 4'd1;
    rob_head = 4'd0;
    #1;
    tb_check1("v8u next old killed bit clear", next_head_killed, 1'b0);
    tb_check1("v8u next same-cycle effective kill",
              next_head_effective_killed, 1'b1);
    clear_events();

    reset_dut();
    push_one(KIND_LOAD, 4'd1, 64'h0000_0000_c200_1000);
    tb_check1("v8u single resident has no next", next_head_valid, 1'b0);
    $display("[V8U-MIQ-NEXT-HEAD] exact current/next, wrap and effective-kill PASS");

    tb_finish("tb_ooo_mem_inflight_queue");
  end

  wire unused_observe_w = full | head_pdest_fp | head_unsigned |
      (|head_rob) | (|head_pdest) | (|head_size) | (|head_wdata) |
      (|head_wstrb) | (|entry_kind) | (|entry_rob) | (|entry_addr) |
      next_head_killed;
endmodule
