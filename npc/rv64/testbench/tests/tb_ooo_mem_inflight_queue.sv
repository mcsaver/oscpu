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
  reg [ROB_INDEX_W-1:0] push_rob;
  reg [PHY_REG_ADDR_W-1:0] push_pdest;
  reg push_pdest_fp;
  reg [1:0] push_size;
  reg push_unsigned;
  reg [`XLEN-1:0] push_addr;
  reg [`XLEN-1:0] push_wdata;
  reg [`STRB_W-1:0] push_wstrb;
  reg pop_valid;
  reg kill_valid;
  reg [ROB_INDEX_W-1:0] kill_rob;
  reg [ROB_INDEX_W-1:0] rob_head;

  wire head_valid;
  wire [1:0] head_kind;
  wire head_killed;
  wire [ROB_INDEX_W-1:0] head_rob;
  wire [PHY_REG_ADDR_W-1:0] head_pdest;
  wire head_pdest_fp;
  wire [1:0] head_size;
  wire head_unsigned;
  wire [`XLEN-1:0] head_addr;
  wire [`XLEN-1:0] head_wdata;
  wire [`STRB_W-1:0] head_wstrb;
  wire [ENTRY_W:0] count;
  wire empty;
  wire full;
  wire [ENTRY_N-1:0] entry_valid;
  wire [ENTRY_N*2-1:0] entry_kind;
  wire [ENTRY_N*ROB_INDEX_W-1:0] entry_rob;
  wire [ENTRY_N*`XLEN-1:0] entry_addr;

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
    .push_rob_idx_i(push_rob),
    .push_pdest_i(push_pdest),
    .push_pdest_fp_i(push_pdest_fp),
    .push_size_i(push_size),
    .push_unsigned_i(push_unsigned),
    .push_eff_addr_i(push_addr),
    .push_wdata_i(push_wdata),
    .push_wstrb_i(push_wstrb),
    .pop_valid_i(pop_valid),
    .kill_valid_i(kill_valid),
    .kill_rob_idx_i(kill_rob),
    .rob_head_idx_i(rob_head),
    .head_valid_o(head_valid),
    .head_kind_o(head_kind),
    .head_killed_o(head_killed),
    .head_rob_idx_o(head_rob),
    .head_pdest_o(head_pdest),
    .head_pdest_fp_o(head_pdest_fp),
    .head_size_o(head_size),
    .head_unsigned_o(head_unsigned),
    .head_eff_addr_o(head_addr),
    .head_wdata_o(head_wdata),
    .head_wstrb_o(head_wstrb),
    .count_o(count),
    .empty_o(empty),
    .full_o(full),
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
    push_rob = {ROB_INDEX_W{1'b0}};
    push_pdest = {PHY_REG_ADDR_W{1'b0}};
    push_pdest_fp = 1'b0;
    push_size = 2'd3;
    push_unsigned = 1'b0;
    push_addr = {`XLEN{1'b0}};
    push_wdata = 64'h0123_4567_89ab_cdef;
    push_wstrb = {`STRB_W{1'b1}};
    pop_valid = 1'b0;
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

    // flush 不带 pop：DRAIN 必须保留，LOAD 被清；kill 不得误杀 retired DRAIN。
    reset_dut();
    push_one(KIND_DRAIN, 4'd1, 64'h8000_1100);
    push_one(KIND_LOAD, 4'd2, 64'h8000_1200);
    flush = 1'b1;
    kill_valid = 1'b1;
    kill_rob = 4'd0;
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

    tb_finish("tb_ooo_mem_inflight_queue");
  end

  wire unused_observe_w = full | head_pdest_fp | head_unsigned |
      (|head_rob) | (|head_pdest) | (|head_size) | (|head_wdata) |
      (|head_wstrb) | (|entry_kind) | (|entry_rob) | (|entry_addr);
endmodule
