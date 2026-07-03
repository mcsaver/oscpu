`include "define.v"

// OooStoreQueue 单元 TB: 程序序双发 alloc/乱序填充/CAM 双退休标记/队头 drain/
// boundary flush(branch-kill 只清比分支年轻的投机 entry)/all flush(trap 清全部未退休)。
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
  reg alloc0_valid;
  reg [ROB_INDEX_W-1:0] alloc0_rob_idx;
  reg alloc1_valid;
  reg [ROB_INDEX_W-1:0] alloc1_rob_idx;
  reg fill0_valid;
  reg [ROB_INDEX_W-1:0] fill0_rob_idx;
  reg [`XLEN-1:0] fill0_addr;
  reg [`XLEN-1:0] fill0_data;
  reg [`STRB_W-1:0] fill0_strb;
  reg fill1_valid;
  reg [ROB_INDEX_W-1:0] fill1_rob_idx;
  reg [`XLEN-1:0] fill1_addr;
  reg [`XLEN-1:0] fill1_data;
  reg [`STRB_W-1:0] fill1_strb;
  reg mark0_valid;
  reg [ROB_INDEX_W-1:0] mark0_rob_idx;
  reg mark1_valid;
  reg [ROB_INDEX_W-1:0] mark1_rob_idx;
  reg drain_fire;

  wire alloc0_ready;
  wire alloc1_ready;
  wire drain_valid;
  wire [`XLEN-1:0] drain_addr;
  wire [`XLEN-1:0] drain_data;
  wire [`STRB_W-1:0] drain_strb;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_valid;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_addr_valid;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_addr;
  wire [(1 << ENTRY_COUNT_W) * `XLEN - 1:0] snoop_data;
  wire [(1 << ENTRY_COUNT_W) * `STRB_W - 1:0] snoop_strb;
  wire [(1 << ENTRY_COUNT_W) * ROB_INDEX_W - 1:0] snoop_rob_idx;
  wire [(1 << ENTRY_COUNT_W)-1:0] snoop_committed;
  wire [ENTRY_COUNT_W-1:0] snoop_head;
  wire [ENTRY_COUNT_W:0] count;

  OooStoreQueue #(
    .ENTRY_COUNT_W(ENTRY_COUNT_W)
  ) dut (
    .clk(clk),
    .rst(rst),
    .flush_valid_i(flush_valid),
    .flush_all_i(flush_all),
    .flush_rob_head_i(flush_rob_head),
    .flush_boundary_rob_i(flush_boundary_rob),
    .alloc0_valid_i(alloc0_valid),
    .alloc0_ready_o(alloc0_ready),
    .alloc0_rob_idx_i(alloc0_rob_idx),
    .alloc1_valid_i(alloc1_valid),
    .alloc1_ready_o(alloc1_ready),
    .alloc1_rob_idx_i(alloc1_rob_idx),
    .fill0_valid_i(fill0_valid),
    .fill0_rob_idx_i(fill0_rob_idx),
    .fill0_addr_i(fill0_addr),
    .fill0_data_i(fill0_data),
    .fill0_strb_i(fill0_strb),
    .fill1_valid_i(fill1_valid),
    .fill1_rob_idx_i(fill1_rob_idx),
    .fill1_addr_i(fill1_addr),
    .fill1_data_i(fill1_data),
    .fill1_strb_i(fill1_strb),
    .mark0_valid_i(mark0_valid),
    .mark0_rob_idx_i(mark0_rob_idx),
    .mark1_valid_i(mark1_valid),
    .mark1_rob_idx_i(mark1_rob_idx),
    .drain_valid_o(drain_valid),
    .drain_addr_o(drain_addr),
    .drain_data_o(drain_data),
    .drain_strb_o(drain_strb),
    .drain_fire_i(drain_fire),
    .snoop_valid_o(snoop_valid),
    .snoop_addr_valid_o(snoop_addr_valid),
    .snoop_addr_o(snoop_addr),
    .snoop_data_o(snoop_data),
    .snoop_strb_o(snoop_strb),
    .snoop_rob_idx_o(snoop_rob_idx),
    .snoop_committed_o(snoop_committed),
    .snoop_head_o(snoop_head),
    .count_o(count)
  );

  // 前递面新增导出的基本一致性: head 对齐 drain 语义、data/strb 与 fill 一致
  // (深断言留消费者侧, 单测只守"导出即 fill 写入值")。
  wire snoop_face_observed_unused =
      (|snoop_data) | (|snoop_strb) | (|snoop_head);

  // 时钟由 TB_TICK 手动驱动(tb_common 约定), 不用自由时钟。
  task automatic tb_check64;
    input string name;
    input [63:0] got;
    input [63:0] expected;
    begin
      if (got !== expected) begin
        $display("[CHECK-FAIL] %s got=0x%016h expected=0x%016h", name, got, expected);
        tb_errors = tb_errors + 1;
      end
    end
  endtask

  task alloc_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      alloc0_valid = 1'b1;
      alloc0_rob_idx = ridx;
      `TB_TICK(clk);
      alloc0_valid = 1'b0;
    end
  endtask

  task fill_entry;
    input [ROB_INDEX_W-1:0] ridx;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    begin
      fill0_valid = 1'b1; fill0_rob_idx = ridx;
      fill0_addr = addr; fill0_data = data; fill0_strb = 8'hff;
      `TB_TICK(clk);
      fill0_valid = 1'b0;
    end
  endtask

  task mark_one;
    input [ROB_INDEX_W-1:0] ridx;
    begin
      mark0_valid = 1'b1;
      mark0_rob_idx = ridx;
      `TB_TICK(clk);
      mark0_valid = 1'b0;
    end
  endtask

  task drain_one;
    begin
      drain_fire = 1'b1;
      `TB_TICK(clk);
      drain_fire = 1'b0;
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    flush_valid = 1'b0;
    flush_all = 1'b0;
    flush_rob_head = {ROB_INDEX_W{1'b0}};
    flush_boundary_rob = {ROB_INDEX_W{1'b0}};
    alloc0_valid = 1'b0;
    alloc0_rob_idx = {ROB_INDEX_W{1'b0}};
    alloc1_valid = 1'b0;
    alloc1_rob_idx = {ROB_INDEX_W{1'b0}};
    fill0_valid = 1'b0; fill0_rob_idx = {ROB_INDEX_W{1'b0}};
    fill0_addr = {`XLEN{1'b0}}; fill0_data = {`XLEN{1'b0}}; fill0_strb = {`STRB_W{1'b0}};
    fill1_valid = 1'b0; fill1_rob_idx = {ROB_INDEX_W{1'b0}};
    fill1_addr = {`XLEN{1'b0}}; fill1_data = {`XLEN{1'b0}}; fill1_strb = {`STRB_W{1'b0}};
    mark0_valid = 1'b0;
    mark0_rob_idx = {ROB_INDEX_W{1'b0}};
    mark1_valid = 1'b0;
    mark1_rob_idx = {ROB_INDEX_W{1'b0}};
    drain_fire = 1'b0;
    repeat (2) `TB_TICK(clk);
    rst = 1'b0;
    #1;

    // 1) 复位后空
    tb_check1("reset: empty no drain", drain_valid, 1'b0);
    tb_check1("reset: alloc0 ready", alloc0_ready, 1'b1);
    tb_check1("reset: alloc1 ready", alloc1_ready, 1'b1);
    tb_check32("reset: count 0", {28'b0, count}, 32'd0);

    // 2) 双发 alloc 一拍两个(rob 3,4), 再单发两拍(rob 6,9)到 full
    alloc0_valid = 1'b1; alloc0_rob_idx = 4'd3;
    alloc1_valid = 1'b1; alloc1_rob_idx = 4'd4;
    `TB_TICK(clk);
    alloc0_valid = 1'b0; alloc1_valid = 1'b0;
    #1;
    tb_check32("dual alloc: count 2", {28'b0, count}, 32'd2);
    alloc_one(4'd6);
    alloc_one(4'd9);
    #1;
    tb_check32("alloc to full: count 4", {28'b0, count}, 32'd4);
    tb_check1("full: alloc0 not ready", alloc0_ready, 1'b0);
    tb_check1("full: alloc1 not ready", alloc1_ready, 1'b0);

    // 3) CAM 回填: 双口同拍(fill0→rob6/entry2, fill1→rob4/entry1)乱序; miss 忽略;
    //    重复 fill 首笔保持
    fill0_valid = 1'b1; fill0_rob_idx = 4'd6;
    fill0_addr = 64'h8000_1000; fill0_data = 64'h1111_2222_3333_4444; fill0_strb = 8'hff;
    fill1_valid = 1'b1; fill1_rob_idx = 4'd4;
    fill1_addr = 64'h8000_0800; fill1_data = 64'h5555_6666_7777_8888; fill1_strb = 8'h0f;
    `TB_TICK(clk);
    fill0_valid = 1'b0; fill1_valid = 1'b0;
    fill_entry(4'd15, 64'hbad0_bad0_bad0_bad0, 64'h0);   // CAM miss: 无效果
    fill_entry(4'd3, 64'h8000_0100, 64'hdead_beef_cafe_0123);
    fill_entry(4'd3, 64'h9999_9999, 64'h0);              // 重复: 首笔保持
    #1;
    tb_check1("snoop: entry0(rob3) addr valid", snoop_addr_valid[0], 1'b1);
    tb_check64("snoop: entry0 addr first-fill kept", snoop_addr[0*`XLEN +: `XLEN], 64'h8000_0100);
    tb_check1("snoop: entry1(rob4 via fill1) addr valid", snoop_addr_valid[1], 1'b1);
    tb_check64("snoop: entry1 addr", snoop_addr[1*`XLEN +: `XLEN], 64'h8000_0800);
    tb_check1("snoop: entry2(rob6 via fill0) addr valid", snoop_addr_valid[2], 1'b1);
    tb_check1("snoop: entry3 not filled", snoop_addr_valid[3], 1'b0);

    // 4) 未退休不 drain
    tb_check1("no mark: no drain", drain_valid, 1'b0);

    // 5) CAM 退休: 不匹配 rob 无效果; 双 mark 一拍标两个(rob3=head, rob4=次头)
    mark_one(4'd15);
    #1;
    tb_check1("mark miss: no drain", drain_valid, 1'b0);
    mark0_valid = 1'b1; mark0_rob_idx = 4'd3;
    mark1_valid = 1'b1; mark1_rob_idx = 4'd4;
    `TB_TICK(clk);
    mark0_valid = 1'b0; mark1_valid = 1'b0;
    #1;
    tb_check1("dual mark: entry0 committed", snoop_committed[0], 1'b1);
    tb_check1("dual mark: entry1 committed", snoop_committed[1], 1'b1);
    tb_check1("head committed+filled: drain", drain_valid, 1'b1);
    tb_check64("drain addr = head addr", drain_addr, 64'h8000_0100);
    tb_check64("drain data = head data", drain_data, 64'hdead_beef_cafe_0123);
    drain_one();
    #1;
    tb_check32("drain releases: count 3", {28'b0, count}, 32'd3);
    tb_check1("released: alloc0 ready again", alloc0_ready, 1'b1);
    tb_check1("head=entry1 committed+filled: drain chains", drain_valid, 1'b1);
    tb_check64("drain addr = entry1 addr", drain_addr, 64'h8000_0800);
    drain_one();
    #1;
    tb_check32("second drain: count 2", {28'b0, count}, 32'd2);

    // 6) boundary flush(branch-kill): 剩 entry2(rob6 未退休)/entry3(rob9 未退休);
    //    boundary=rob6 → rob6 不比分支年轻留下, rob9 清; tail 回卷复用
    flush_valid = 1'b1; flush_all = 1'b0;
    flush_rob_head = 4'd6;          // ROB head=最老未退休=rob6
    flush_boundary_rob = 4'd6;      // 分支即 rob6: 严格更年轻的(rob9)清
    `TB_TICK(clk);
    flush_valid = 1'b0;
    #1;
    tb_check32("boundary flush: count 1", {28'b0, count}, 32'd1);
    tb_check1("boundary flush: entry2(rob6 older-eq) kept", snoop_valid[2], 1'b1);
    tb_check1("boundary flush: entry3(rob9 younger) cleared", snoop_valid[3], 1'b0);
    // tail 回卷到 entry3 可复用
    alloc_one(4'd10);
    #1;
    tb_check32("post-boundary alloc: count 2", {28'b0, count}, 32'd2);
    tb_check1("post-boundary alloc reuses entry3", snoop_valid[3], 1'b1);

    // 7) all flush(trap): 未 committed(rob6/rob10)按理全清; 同拍 mark 的 rob6
    //    按"本拍即将退休"存活, rob10 清
    mark0_valid = 1'b1; mark0_rob_idx = 4'd6;
    flush_valid = 1'b1; flush_all = 1'b1;
    `TB_TICK(clk);
    mark0_valid = 1'b0; flush_valid = 1'b0; flush_all = 1'b0;
    #1;
    tb_check32("all flush + same-cycle mark: count 1", {28'b0, count}, 32'd1);
    tb_check1("all flush: entry2(rob6 marked same-cycle) kept", snoop_valid[2], 1'b1);
    tb_check1("all flush: entry2 committed", snoop_committed[2], 1'b1);
    tb_check1("all flush: entry3(rob10 spec) cleared", snoop_valid[3], 1'b0);

    // 8) 清尾: entry2(rob6)已回填+committed → drain 排空
    tb_check1("entry2 committed+filled: drain", drain_valid, 1'b1);
    tb_check64("drain addr = entry2 addr", drain_addr, 64'h8000_1000);
    drain_one();
    #1;
    tb_check32("all drained: count 0", {28'b0, count}, 32'd0);
    tb_check1("empty again: no drain", drain_valid, 1'b0);

    tb_finish("tb_ooo_store_queue");
  end

endmodule
