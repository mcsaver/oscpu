`include "define.v"

// T4N focused unit test: probe fill, physical request fire, B/probe terminal,
// and ROB release are separate events.  It also covers VA!=PA ownership,
// physical-head ordering, branch survival, global speculative squash, and
// request at-most-once behavior.
module tb_ooo_store_queue;
  `include "tb_common.svh"

  localparam ENTRY_COUNT_W = 2;
  localparam ROB_INDEX_W = `OOO_ROB_INDEX_W;

  reg clk;
  reg rst;
  reg flush_valid;
  reg flush_all;
  reg [ROB_INDEX_W-1:0] flush_rob_head;
  reg [ROB_INDEX_W-1:0] flush_boundary_rob;
  reg rob_head_valid;
  reg [ROB_INDEX_W-1:0] rob_head_idx;
  reg alloc0_valid;
  reg [ROB_INDEX_W-1:0] alloc0_rob_idx;
  reg alloc1_valid;
  reg [ROB_INDEX_W-1:0] alloc1_rob_idx;
  reg fill0_valid;
  reg [ROB_INDEX_W-1:0] fill0_rob_idx;
  reg [`XLEN-1:0] fill0_vaddr;
  reg [`XLEN-1:0] fill0_paddr;
  reg fill0_attr_valid;
  reg [1:0] fill0_class;
  reg fill0_cacheable;
  reg [`XLEN-1:0] fill0_data;
  reg [`STRB_W-1:0] fill0_strb;
  reg fill1_valid;
  reg [ROB_INDEX_W-1:0] fill1_rob_idx;
  reg [`XLEN-1:0] fill1_vaddr;
  reg [`XLEN-1:0] fill1_paddr;
  reg fill1_attr_valid;
  reg [1:0] fill1_class;
  reg fill1_cacheable;
  reg [`XLEN-1:0] fill1_data;
  reg [`STRB_W-1:0] fill1_strb;
  reg terminal_valid;
  reg [ROB_INDEX_W-1:0] terminal_rob_idx;
  reg terminal1_valid;
  reg [ROB_INDEX_W-1:0] terminal1_rob_idx;
  reg release_valid;
  reg [ROB_INDEX_W-1:0] release_rob_idx;
  reg req_fire;

  wire alloc0_ready;
  wire alloc1_ready;
  wire release_ready;
  wire release_fire;
  wire req_valid;
  wire [ROB_INDEX_W-1:0] req_rob_idx;
  wire [`XLEN-1:0] req_vaddr;
  wire [`XLEN-1:0] req_paddr;
  wire req_attr_valid;
  wire [1:0] req_class;
  wire req_cacheable;
  wire [`XLEN-1:0] req_data;
  wire [`STRB_W-1:0] req_strb;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_valid;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_addr_valid;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_addr;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_paddr;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_attr_valid;
  wire [(1 << ENTRY_COUNT_W) * 2 - 1:0] snoop_class;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_cacheable;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_data;
  wire [(1 << ENTRY_COUNT_W) * `STRB_W - 1:0] snoop_strb;
  wire [(1 << ENTRY_COUNT_W) * ROB_INDEX_W - 1:0] snoop_rob_idx;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_request_sent;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_terminal;
  wire [ENTRY_COUNT_W-1:0] snoop_head;
  wire [ENTRY_COUNT_W:0] count;

  OooStoreQueue #(
    .ENTRY_COUNT_W(ENTRY_COUNT_W),
    .ROB_INDEX_W(ROB_INDEX_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(flush_valid),
    .flush_all_i(flush_all),
    .flush_rob_head_i(flush_rob_head),
    .flush_boundary_rob_i(flush_boundary_rob),
    .rob_head_valid_i(rob_head_valid),
    .rob_head_idx_i(rob_head_idx),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_rob_idx_i(alloc0_rob_idx),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_rob_idx_i(alloc1_rob_idx),
    .fill0_valid_i(fill0_valid),
    .fill0_rob_idx_i(fill0_rob_idx),
    .fill0_vaddr_i(fill0_vaddr),
    .fill0_paddr_i(fill0_paddr),
    .fill0_attr_valid_i(fill0_attr_valid),
    .fill0_class_i(fill0_class),
    .fill0_cacheable_i(fill0_cacheable),
    .fill0_data_i(fill0_data),
    .fill0_strb_i(fill0_strb),
    .fill1_valid_i(fill1_valid),
    .fill1_rob_idx_i(fill1_rob_idx),
    .fill1_vaddr_i(fill1_vaddr),
    .fill1_paddr_i(fill1_paddr),
    .fill1_attr_valid_i(fill1_attr_valid),
    .fill1_class_i(fill1_class),
    .fill1_cacheable_i(fill1_cacheable),
    .fill1_data_i(fill1_data),
    .fill1_strb_i(fill1_strb),
    .terminal_valid_i(terminal_valid),
    .terminal_rob_idx_i(terminal_rob_idx),
    .terminal1_valid_i(terminal1_valid),
    .terminal1_rob_idx_i(terminal1_rob_idx),
    .release_valid_i(release_valid),
    .release_rob_idx_i(release_rob_idx),
    .release_ready_o(release_ready),
    .release_fire_o(release_fire),
    .req_valid_o(req_valid),
    .req_rob_idx_o(req_rob_idx),
    .req_vaddr_o(req_vaddr),
    .req_paddr_o(req_paddr),
    .req_attr_valid_o(req_attr_valid),
    .req_class_o(req_class),
    .req_cacheable_o(req_cacheable),
    .req_data_o(req_data),
    .req_strb_o(req_strb),
    .req_fire_i(req_fire),
    .snoop_valid_o(snoop_valid),
    .snoop_addr_valid_o(snoop_addr_valid),
    .snoop_addr_o(snoop_addr),
    .snoop_paddr_o(snoop_paddr),
    .snoop_attr_valid_o(snoop_attr_valid),
    .snoop_class_o(snoop_class),
    .snoop_cacheable_o(snoop_cacheable),
    .snoop_data_o(snoop_data),
    .snoop_strb_o(snoop_strb),
    .snoop_rob_idx_o(snoop_rob_idx),
    .snoop_request_sent_o(snoop_request_sent),
    .snoop_terminal_o(snoop_terminal),
    .snoop_head_o(snoop_head),
    .count_o(count)
  );

  task automatic check64;
    input string name;
    input [63:0] got;
    input [63:0] expected;
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=0x%016h expected=0x%016h",
                 name, got, expected);
        tb_errors = tb_errors + 1;
      end
    end
  endtask

  task automatic alloc_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      alloc0_valid = 1'b1;
      alloc0_rob_idx = ridx;
      `TB_TICK(clk);
      alloc0_valid = 1'b0;
    end
  endtask

  task automatic fill_one;
    input [ROB_INDEX_W-1:0] ridx;
    input [`XLEN-1:0] va;
    input [`XLEN-1:0] pa;
    input [`XLEN-1:0] data;
    begin
      fill0_valid = 1'b1;
      fill0_rob_idx = ridx;
      fill0_vaddr = va;
      fill0_paddr = pa;
      fill0_attr_valid = 1'b1;
      fill0_class = `OOO_MEM_CLASS_CACHED;
      fill0_cacheable = 1'b1;
      fill0_data = data;
      fill0_strb = 8'hff;
      `TB_TICK(clk);
      fill0_valid = 1'b0;
      fill0_attr_valid = 1'b0;
      fill0_class = `OOO_MEM_CLASS_RSVD;
      fill0_cacheable = 1'b0;
    end
  endtask

  task automatic send_terminal;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      terminal_valid = 1'b1;
      terminal_rob_idx = ridx;
      `TB_TICK(clk);
      terminal_valid = 1'b0;
    end
  endtask

  task automatic release_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      release_valid = 1'b1;
      release_rob_idx = ridx;
      `TB_TICK(clk);
      release_valid = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    flush_valid = 1'b0;
    flush_all = 1'b0;
    flush_rob_head = '0;
    flush_boundary_rob = '0;
    rob_head_valid = 1'b0;
    rob_head_idx = '0;
    alloc0_valid = 1'b0;
    alloc0_rob_idx = '0;
    alloc1_valid = 1'b0;
    alloc1_rob_idx = '0;
    fill0_valid = 1'b0;
    fill0_rob_idx = '0;
    fill0_vaddr = '0;
    fill0_paddr = '0;
    fill0_attr_valid = 1'b0;
    fill0_class = `OOO_MEM_CLASS_RSVD;
    fill0_cacheable = 1'b0;
    fill0_data = '0;
    fill0_strb = '0;
    fill1_valid = 1'b0;
    fill1_rob_idx = '0;
    fill1_vaddr = '0;
    fill1_paddr = '0;
    fill1_attr_valid = 1'b0;
    fill1_class = `OOO_MEM_CLASS_RSVD;
    fill1_cacheable = 1'b0;
    fill1_data = '0;
    fill1_strb = '0;
    terminal_valid = 1'b0;
    terminal_rob_idx = '0;
    terminal1_valid = 1'b0;
    terminal1_rob_idx = '0;
    release_valid = 1'b0;
    release_rob_idx = '0;
    req_fire = 1'b0;
    repeat (2) `TB_TICK(clk);
    rst = 1'b0;
    #1;

    tb_check32("reset count", {28'b0, count}, 32'd0);
    tb_check1("reset request invalid", req_valid, 1'b0);

    // Four stores, with the first two allocated together.
    alloc0_valid = 1'b1; alloc0_rob_idx = 4'd3;
    alloc1_valid = 1'b1; alloc1_rob_idx = 4'd4;
    `TB_TICK(clk);
    alloc0_valid = 1'b0; alloc1_valid = 1'b0;
    alloc_one(4'd6);
    alloc_one(4'd9);
    #1;
    tb_check32("full count", {28'b0, count}, 32'd4);
    tb_check1("full blocks alloc0", alloc0_ready, 1'b0);

    // Out-of-order fill.  The request face must retain both original VA and PA.
    fill1_valid = 1'b1; fill1_rob_idx = 4'd4;
    fill1_vaddr = 64'h0000_0000_0000_2000;
    fill1_paddr = 64'h0000_0000_8000_2000;
    fill1_attr_valid = 1'b1;
    fill1_class = `OOO_MEM_CLASS_NC;
    fill1_cacheable = 1'b0;
    fill1_data = 64'h4444_4444_4444_4444;
    fill1_strb = 8'hff;
    fill0_valid = 1'b1; fill0_rob_idx = 4'd6;
    fill0_vaddr = 64'h0000_0000_0000_3000;
    fill0_paddr = 64'h0000_0000_8000_3000;
    fill0_attr_valid = 1'b1;
    fill0_class = `OOO_MEM_CLASS_CACHED;
    fill0_cacheable = 1'b1;
    fill0_data = 64'h6666_6666_6666_6666;
    fill0_strb = 8'hff;
    `TB_TICK(clk);
    fill0_valid = 1'b0; fill1_valid = 1'b0;
    fill0_attr_valid = 1'b0; fill1_attr_valid = 1'b0;
    fill0_class = `OOO_MEM_CLASS_RSVD;
    fill1_class = `OOO_MEM_CLASS_RSVD;
    fill0_cacheable = 1'b0; fill1_cacheable = 1'b0;
    fill_one(4'd3, 64'h0000_0000_0000_1000,
             64'h0000_0000_8000_1000, 64'h3333_3333_3333_3333);

    rob_head_valid = 1'b1;
    rob_head_idx = 4'd4;
    #1;
    tb_check1("physical head mismatch blocks request", req_valid, 1'b0);
    rob_head_idx = 4'd3;
    #1;
    tb_check1("head match exposes request", req_valid, 1'b1);
    tb_check32("head request ROB", {28'b0, req_rob_idx}, 32'd3);
    check64("request retains VA", req_vaddr, 64'h0000_0000_0000_1000);
    check64("request uses PA", req_paddr, 64'h0000_0000_8000_1000);
    tb_check1("request retains post-translate cacheable class",
              req_cacheable, 1'b1);
    tb_check1("request typed attr valid", req_attr_valid, 1'b1);
    tb_check32("request typed CACHED class", {30'b0, req_class},
               {30'b0, `OOO_MEM_CLASS_CACHED});
    check64("physical snoop view uses PA",
            snoop_paddr[0*`XLEN +: `XLEN],
            64'h0000_0000_8000_1000);
    tb_check1("physical snoop cacheable class visible",
              snoop_cacheable[0], 1'b1);
    tb_check1("physical snoop typed attr visible",
              snoop_attr_valid[0], 1'b1);
    tb_check32("physical snoop CACHED class visible",
               {30'b0, snoop_class[0*2 +: 2]},
               {30'b0, `OOO_MEM_CLASS_CACHED});

    // Event 1: physical request fire.  Owner/count/forwarding remain; no duplicate.
    req_fire = 1'b1;
    `TB_TICK(clk);
    req_fire = 1'b0;
    #1;
    tb_check32("request fire keeps owner", {28'b0, count}, 32'd4);
    tb_check1("request at-most-once", req_valid, 1'b0);
    tb_check1("request-sent visible", snoop_request_sent[0], 1'b1);
    tb_check1("pre-B release blocked", release_ready, 1'b0);
    check64("forwarding VA persists", snoop_addr[0*`XLEN +: `XLEN],
            64'h0000_0000_0000_1000);

    // Active owner survives a branch flush; only strictly younger-than-boundary
    // suffix (rob9) is removed.
    flush_valid = 1'b1;
    flush_all = 1'b0;
    flush_rob_head = 4'd3;
    flush_boundary_rob = 4'd6;
    `TB_TICK(clk);
    flush_valid = 1'b0;
    #1;
    tb_check32("branch flush keeps active prefix", {28'b0, count}, 32'd3);
    tb_check1("active owner survives branch", snoop_request_sent[0], 1'b1);
    tb_check1("younger suffix removed", snoop_valid[3], 1'b0);

    // Event 2: B response terminal.  Owner still resident and becomes releasable.
    send_terminal(4'd3);
    #1;
    tb_check32("B terminal keeps owner", {28'b0, count}, 32'd3);
    tb_check1("terminal visible", snoop_terminal[0], 1'b1);
    release_rob_idx = 4'd3;
    #1;
    tb_check1("terminal enables release", release_ready, 1'b1);

    // Event 3: ROB commit/release.  Only now does the physical head advance.
    release_one(4'd3);
    #1;
    tb_check32("ROB release removes owner", {28'b0, count}, 32'd2);
    rob_head_idx = 4'd4;
    #1;
    tb_check1("second store follows physical order", req_valid, 1'b1);
    tb_check32("second request ROB", {28'b0, req_rob_idx}, 32'd4);
    check64("second request PA", req_paddr, 64'h0000_0000_8000_2000);
    tb_check1("second request retains NC/IO class", req_cacheable, 1'b0);
    tb_check1("second request typed attr valid", req_attr_valid, 1'b1);
    tb_check32("second request retains exact NC class",
               {30'b0, req_class}, {30'b0, `OOO_MEM_CLASS_NC});

    req_fire = 1'b1; `TB_TICK(clk); req_fire = 1'b0;
    send_terminal(4'd4);
    release_one(4'd4);
    #1;
    tb_check32("second store released", {28'b0, count}, 32'd1);

    // Probe fault terminal can arrive without fill/request, and same-cycle
    // terminal+ROB release is accepted through the terminal bypass.
    rob_head_idx = 4'd6;
    terminal_valid = 1'b1;
    terminal_rob_idx = 4'd6;
    release_valid = 1'b1;
    release_rob_idx = 4'd6;
    #1;
    tb_check1("same-cycle terminal release ready", release_ready, 1'b1);
    `TB_TICK(clk);
    terminal_valid = 1'b0;
    release_valid = 1'b0;
    #1;
    tb_check32("fault store released", {28'b0, count}, 32'd0);

    // Global flush is only used with speculative entries; no live physical owner
    // may be silently nuked.
    alloc_one(4'd10);
    alloc_one(4'd11);
    flush_valid = 1'b1;
    flush_all = 1'b1;
    flush_rob_head = 4'd10;
    `TB_TICK(clk);
    flush_valid = 1'b0;
    flush_all = 1'b0;
    #1;
    tb_check32("global flush clears speculation", {28'b0, count}, 32'd0);
    tb_check1("empty request invalid", req_valid, 1'b0);

    // Reviewer event algebra: one terminal head release and two fresh dispatch
    // allocations are independent ports.  Occupancy is old(1)-release(1)+alloc(2).
    alloc_one(4'd12);
    send_terminal(4'd12);
    release_valid = 1'b1;
    release_rob_idx = 4'd12;
    alloc0_valid = 1'b1;
    alloc0_rob_idx = 4'd13;
    alloc1_valid = 1'b1;
    alloc1_rob_idx = 4'd14;
    #1;
    tb_check1("release+alloc release ready", release_ready, 1'b1);
    tb_check1("release+alloc alloc0 ready", alloc0_ready, 1'b1);
    tb_check1("release+alloc alloc1 ready", alloc1_ready, 1'b1);
    `TB_TICK(clk);
    release_valid = 1'b0;
    alloc0_valid = 1'b0;
    alloc1_valid = 1'b0;
    #1;
    tb_check32("release+dual-alloc count", {28'b0, count}, 32'd2);
    tb_check1("release+dual-alloc new head valid", snoop_valid[snoop_head], 1'b1);
    tb_check32("release+dual-alloc new head ROB",
               {{(32-ROB_INDEX_W){1'b0}},
                snoop_rob_idx[snoop_head*ROB_INDEX_W +: ROB_INDEX_W]},
               32'd13);
    $display("[T4N-SQ-RELEASE-DUAL-ALLOC] count=2 head_rob=13 PASS");

    // 两个不同 terminal tag 同拍各命中一次，不能由单 tag mux 丢掉一路。
    terminal_valid = 1'b1;
    terminal_rob_idx = 4'd13;
    terminal1_valid = 1'b1;
    terminal1_rob_idx = 4'd14;
`ifdef T4N_DUAL_TERMINAL_SAME_TAG_NEGATIVE
    terminal1_rob_idx = 4'd13;
    $display("[T4N-DUAL-TERMINAL-SAME-TAG-NEGATIVE] forced both terminal tags to rob13");
`endif
    `TB_TICK(clk);
    terminal_valid = 1'b0;
    terminal1_valid = 1'b0;
    #1;
    tb_check1("dual terminal marks head",
              snoop_terminal[snoop_head], 1'b1);
    tb_check1("dual terminal marks next",
              snoop_terminal[snoop_head + 1'b1], 1'b1);
    release_one(4'd13);
    release_one(4'd14);
    #1;
    tb_check32("dual terminal pair releases in order", {28'b0, count}, 32'd0);
    $display("[T4N-SQ-DUAL-TERMINAL] distinct ROB tags both sticky PASS");

    // Terminal+B, ROB release and global flush may coincide for the accepted
    // physical head.  Same-cycle terminal bypass authorizes release, and the
    // flush keep/release algebra must leave neither a ghost nor a nuke error.
    alloc_one(4'd15);
    fill_one(4'd15, 64'h0000_0000_0000_5000,
             64'h0000_0000_8000_5000, 64'hf5f5_f5f5_f5f5_f5f5);
    rob_head_valid = 1'b1;
    rob_head_idx = 4'd15;
    #1;
    tb_check1("terminal+release+flush request visible", req_valid, 1'b1);
    req_fire = 1'b1;
    `TB_TICK(clk);
    req_fire = 1'b0;
    terminal_valid = 1'b1;
    terminal_rob_idx = 4'd15;
    release_valid = 1'b1;
    release_rob_idx = 4'd15;
    flush_valid = 1'b1;
    flush_all = 1'b1;
    flush_rob_head = 4'd15;
    #1;
    tb_check1("terminal+release+flush same-cycle ready", release_ready, 1'b1);
    `TB_TICK(clk);
    terminal_valid = 1'b0;
    release_valid = 1'b0;
    flush_valid = 1'b0;
    flush_all = 1'b0;
    #1;
    tb_check32("terminal+release+flush leaves empty", {28'b0, count}, 32'd0);
    tb_check1("terminal+release+flush no ghost request", req_valid, 1'b0);
    tb_check32("terminal+release+flush no ghost owner",
               {28'b0, snoop_request_sent}, 32'd0);
    $display("[T4N-SQ-TERMINAL-RELEASE-GLOBAL-FLUSH] accepted owner released exactly once PASS");

    tb_finish("tb_ooo_store_queue");
  end
endmodule
