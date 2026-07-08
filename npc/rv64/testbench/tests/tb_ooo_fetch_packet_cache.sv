`include "define.v"

module tb_ooo_fetch_packet_cache;
  `include "tb_common.svh"

  reg clk;
  reg rst;
  reg clear;

  reg lookup_paging;
  reg [1:0] lookup_priv;
  reg [`XLEN-1:0] lookup_satp;
  reg [`XLEN-1:0] lookup_pc;
  wire lookup_context_hit;
  wire lookup_hit;
  wire [`INST_W-1:0] lookup_inst0;
  wire [1:0] lookup_resp0;
  wire [`INST_W-1:0] lookup_inst1;
  wire [1:0] lookup_resp1;

  reg fill_valid;
  reg fill_paging;
  reg [1:0] fill_priv;
  reg [`XLEN-1:0] fill_satp;
  reg [`XLEN-1:0] fill_pc;
  reg [`INST_W-1:0] fill_inst0;
  reg [1:0] fill_resp0;
  reg [`INST_W-1:0] fill_inst1;
  reg [1:0] fill_resp1;

  reg invalidate_valid;
  reg [`XLEN-1:0] invalidate_addr;

  localparam [`XLEN-1:0] PC0 = 64'h0000_0000_8000_1000;
  localparam [`XLEN-1:0] PC1 = 64'h0000_0000_8000_1010;
  localparam [`XLEN-1:0] PC2 = 64'h0000_0000_8000_1020;
  localparam [`XLEN-1:0] SATP0 = 64'h8000_0000_0000_0123;
  localparam [`XLEN-1:0] SATP1 = 64'h8000_0000_0000_0456;

  OooFetchPacketCache #(
    .INDEX_W(4)
  ) dut (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .lookup_paging_i(lookup_paging),
    .lookup_priv_i(lookup_priv),
    .lookup_satp_i(lookup_satp),
    .lookup_pc_i(lookup_pc),
    .lookup_context_hit_o(lookup_context_hit),
    .lookup_hit_o(lookup_hit),
    .lookup_inst0_o(lookup_inst0),
    .lookup_resp0_o(lookup_resp0),
    .lookup_inst1_o(lookup_inst1),
    .lookup_resp1_o(lookup_resp1),
    .fill_valid_i(fill_valid),
    .fill_paging_i(fill_paging),
    .fill_priv_i(fill_priv),
    .fill_satp_i(fill_satp),
    .fill_pc_i(fill_pc),
    .fill_inst0_i(fill_inst0),
    .fill_resp0_i(fill_resp0),
    .fill_inst1_i(fill_inst1),
    .fill_resp1_i(fill_resp1),
    .invalidate_valid_i(invalidate_valid),
    .invalidate_addr_i(invalidate_addr)
  );

  OooFetchPacketCacheChecker u_checker (
    .clk(clk),
    .rst(rst),
    .clear_i(clear),
    .lookup_paging_i(lookup_paging),
    .lookup_priv_i(lookup_priv),
    .lookup_satp_i(lookup_satp),
    .lookup_pc_i(lookup_pc),
    .lookup_context_hit_i(lookup_context_hit),
    .lookup_hit_i(lookup_hit),
    .fill_valid_i(fill_valid),
    .fill_paging_i(fill_paging),
    .fill_priv_i(fill_priv),
    .fill_satp_i(fill_satp),
    .fill_pc_i(fill_pc),
    .invalidate_valid_i(invalidate_valid),
    .invalidate_addr_i(invalidate_addr)
  );

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

  task automatic tick;
    begin
      `TB_TICK(clk)
    end
  endtask

  task automatic clear_inputs;
    begin
      clear = 1'b0;
      lookup_paging = 1'b0;
      lookup_priv = 2'd0;
      lookup_satp = {`XLEN{1'b0}};
      lookup_pc = PC0;
      fill_valid = 1'b0;
      fill_paging = 1'b0;
      fill_priv = 2'd0;
      fill_satp = {`XLEN{1'b0}};
      fill_pc = PC0;
      fill_inst0 = {`INST_W{1'b0}};
      fill_resp0 = 2'b00;
      fill_inst1 = {`INST_W{1'b0}};
      fill_resp1 = 2'b00;
      invalidate_valid = 1'b0;
      invalidate_addr = {`XLEN{1'b0}};
    end
  endtask

  task automatic fill_packet;
    input do_paging;
    input [1:0] priv;
    input [`XLEN-1:0] satp;
    input [`XLEN-1:0] pc;
    input [`INST_W-1:0] inst0;
    input [1:0] resp0;
    input [`INST_W-1:0] inst1;
    input [1:0] resp1;
    begin
      fill_paging = do_paging;
      fill_priv = priv;
      fill_satp = satp;
      fill_pc = pc;
      fill_inst0 = inst0;
      fill_resp0 = resp0;
      fill_inst1 = inst1;
      fill_resp1 = resp1;
      fill_valid = 1'b1;
      tick();
      fill_valid = 1'b0;
      #1;
    end
  endtask

  task automatic set_lookup;
    input do_paging;
    input [1:0] priv;
    input [`XLEN-1:0] satp;
    input [`XLEN-1:0] pc;
    begin
      lookup_paging = do_paging;
      lookup_priv = priv;
      lookup_satp = satp;
      lookup_pc = pc;
      #1;
    end
  endtask

  task automatic expect_lookup;
    input [1023:0] label;
    input exp_context_hit;
    input exp_hit;
    input [`INST_W-1:0] exp_inst0;
    input [1:0] exp_resp0;
    input [`INST_W-1:0] exp_inst1;
    input [1:0] exp_resp1;
    begin
      tb_check1({label, " context"}, lookup_context_hit, exp_context_hit);
      tb_check1({label, " hit"}, lookup_hit, exp_hit);
      if (exp_hit) begin
        tb_check32({label, " inst0"}, lookup_inst0, exp_inst0);
        tb_check32({label, " resp0"}, {30'b0, lookup_resp0},
                   {30'b0, exp_resp0});
        tb_check32({label, " inst1"}, lookup_inst1, exp_inst1);
        tb_check32({label, " resp1"}, {30'b0, lookup_resp1},
                   {30'b0, exp_resp1});
      end
    end
  endtask

  initial begin
    tb_errors = 0;
    clk = 1'b0;
    rst = 1'b1;
    clear_inputs();
    tick();
    tick();
    rst = 1'b0;
    #1;

    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC0);
    expect_lookup("reset miss", 1'b0, 1'b0, 32'h0, 2'b00, 32'h0, 2'b00);

    fill_packet(1'b0, 2'd0, {`XLEN{1'b0}}, PC0,
                32'h0000_0013, 2'b00, 32'h0000_8093, 2'b01);
    set_lookup(1'b0, 2'd3, SATP1, PC0);
    expect_lookup("bare mode hit", 1'b1, 1'b1,
                  32'h0000_0013, 2'b00, 32'h0000_8093, 2'b01);

    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC0 + 64'h20);
    expect_lookup("same index pc mismatch", 1'b1, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);

    fill_packet(1'b1, 2'd1, SATP0, PC1,
                32'h0000_0113, 2'b10, 32'h0000_8193, 2'b00);
    set_lookup(1'b1, 2'd0, SATP0, PC1);
    expect_lookup("priv mismatch", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);
    set_lookup(1'b1, 2'd1, SATP1, PC1);
    expect_lookup("satp mismatch", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);
    set_lookup(1'b1, 2'd1, SATP0, PC1);
    expect_lookup("paged hit", 1'b1, 1'b1,
                  32'h0000_0113, 2'b10, 32'h0000_8193, 2'b00);

    invalidate_addr = PC0 + 64'd6;
    invalidate_valid = 1'b1;
    tick();
    invalidate_valid = 1'b0;
    #1;
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC0);
    expect_lookup("store invalidates packet", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);
    set_lookup(1'b1, 2'd1, SATP0, PC1);
    expect_lookup("store keeps other packet", 1'b1, 1'b1,
                  32'h0000_0113, 2'b10, 32'h0000_8193, 2'b00);

    // 【§3.1 #1 SMC 足迹 8B】8B store 改写区 [base,base+7] 跨两个 4B 块。缓存在 pc=base+4
    // (idx base+2=p4)/base+6(idx base+3=p6)的高半取指包, 原 4B 足迹(+3)+邻域仅到 base+1 漏失效。
    // 填 PC1+4/PC1+6 包 → 用 addr=PC1 失效(模拟 8B SD 足迹 [PC1,PC1+7]) → 应失效。
    // 修复前: +3 足迹 PC1+3<PC1+4 且邻域无 p4/p6 → 漏(旧码被当新码取回); 修复后 +7 足迹+p4/p6 命中。
    fill_packet(1'b0, 2'd0, {`XLEN{1'b0}}, PC1 + 64'd4,
                32'h0000_0a13, 2'b00, 32'h0000_ab93, 2'b00);
    fill_packet(1'b0, 2'd0, {`XLEN{1'b0}}, PC1 + 64'd6,
                32'h0000_0c13, 2'b00, 32'h0000_cd93, 2'b00);
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC1 + 64'd4);
    expect_lookup("8B high-half p4 cached", 1'b1, 1'b1,
                  32'h0000_0a13, 2'b00, 32'h0000_ab93, 2'b00);
    invalidate_addr = PC1;
    invalidate_valid = 1'b1;
    tick();
    invalidate_valid = 1'b0;
    #1;
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC1 + 64'd4);
    expect_lookup("8B store invalidates p4 high-half (#3A)", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC1 + 64'd6);
    expect_lookup("8B store invalidates p6 high-half (#3A)", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);

    invalidate_addr = PC2 + 64'd2;
    invalidate_valid = 1'b1;
    fill_paging = 1'b0;
    fill_priv = 2'd0;
    fill_satp = {`XLEN{1'b0}};
    fill_pc = PC2;
    fill_inst0 = 32'h0000_0213;
    fill_resp0 = 2'b00;
    fill_inst1 = 32'h0000_8293;
    fill_resp1 = 2'b00;
    fill_valid = 1'b1;
    tick();
    invalidate_valid = 1'b0;
    fill_valid = 1'b0;
    #1;
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC2);
    expect_lookup("store blocks same-window fill", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);

    fill_packet(1'b0, 2'd0, {`XLEN{1'b0}}, PC2,
                32'h0000_0213, 2'b00, 32'h0000_8293, 2'b00);
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC2);
    expect_lookup("refill after blocked fill", 1'b1, 1'b1,
                  32'h0000_0213, 2'b00, 32'h0000_8293, 2'b00);

    clear = 1'b1;
    tick();
    clear = 1'b0;
    #1;
    set_lookup(1'b0, 2'd0, {`XLEN{1'b0}}, PC2);
    expect_lookup("clear drops packet", 1'b0, 1'b0,
                  32'h0, 2'b00, 32'h0, 2'b00);

    tb_check64("lookup pc preserved", lookup_pc, PC2);
    tb_finish("tb_ooo_fetch_packet_cache");
  end
endmodule
