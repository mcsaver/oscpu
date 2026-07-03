`include "define.v"

module tb_ooo_data_word_cache;
  `include "tb_common.svh"

  reg clk;
  reg rst;

  reg [`XLEN-1:0] req_lookup_addr;
  wire req_cacheable;
  wire req_hit;
  wire [`XLEN-1:0] req_data;

  reg [`XLEN-1:0] walk_lookup_addr;
  wire walk_cacheable;
  wire walk_hit;
  wire [`XLEN-1:0] walk_data;

  reg fill_valid;
  reg [`XLEN-1:0] fill_addr;
  reg [`XLEN-1:0] fill_data;

  reg store_commit;
  reg store_invalidate_all;
  reg [`XLEN-1:0] store_addr;
  reg [`XLEN-1:0] store_data;
  reg [`STRB_W-1:0] store_wstrb;

  localparam [`XLEN-1:0] WORD0 = `NPC_AXI_PMEM_BASE + 64'h0000_1000;
  localparam [`XLEN-1:0] WORD1 = `NPC_AXI_PMEM_BASE + 64'h0000_1008;
  localparam [`XLEN-1:0] WORD2 = `NPC_AXI_PMEM_BASE + 64'h0000_1010;
  localparam [`XLEN-1:0] MMIO_WORD = 64'h0000_0000_1000_0000;

  OooDataWordCache #(
    .INDEX_W(2)
  ) dut (
    .clk(clk),
    .rst(rst),
    .req_lookup_addr_i(req_lookup_addr),
    .req_nbytes_i(4'd8),
    .req_line_cross_o(),
    .req_cacheable_o(req_cacheable),
    .req_hit_o(req_hit),
    .req_data_o(req_data),
    .walk_lookup_addr_i(walk_lookup_addr),
    .walk_cacheable_o(walk_cacheable),
    .walk_hit_o(walk_hit),
    .walk_data_o(walk_data),
    .fill_valid_i(fill_valid),
    .fill_addr_i(fill_addr),
    .fill_data_i(fill_data),
    .store_commit_i(store_commit),
    .store_invalidate_all_i(store_invalidate_all),
    .store_addr_i(store_addr),
    .store_data_i(store_data),
    .store_wstrb_i(store_wstrb)
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
      req_lookup_addr = WORD0;
      walk_lookup_addr = WORD0;
      fill_valid = 1'b0;
      fill_addr = {`XLEN{1'b0}};
      fill_data = {`XLEN{1'b0}};
      store_commit = 1'b0;
      store_invalidate_all = 1'b0;
      store_addr = {`XLEN{1'b0}};
      store_data = {`XLEN{1'b0}};
      store_wstrb = {`STRB_W{1'b0}};
    end
  endtask

  task automatic fill_word;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    begin
      fill_addr = addr;
      fill_data = data;
      fill_valid = 1'b1;
      tick();
      fill_valid = 1'b0;
      #1;
    end
  endtask

  task automatic commit_store;
    input [`XLEN-1:0] addr;
    input [`XLEN-1:0] data;
    input [`STRB_W-1:0] strb;
    input invalidate_all;
    begin
      store_addr = addr;
      store_data = data;
      store_wstrb = strb;
      store_invalidate_all = invalidate_all;
      store_commit = 1'b1;
      tick();
      store_commit = 1'b0;
      store_invalidate_all = 1'b0;
      #1;
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

    req_lookup_addr = WORD0;
    walk_lookup_addr = WORD0;
    #1;
    tb_check1("reset req cacheable", req_cacheable, 1'b1);
    tb_check1("reset req miss", req_hit, 1'b0);
    tb_check1("reset walk miss", walk_hit, 1'b0);

    fill_word(WORD0, 64'h0011_2233_4455_6677);
    req_lookup_addr = WORD0;
    walk_lookup_addr = WORD0;
    #1;
    tb_check1("fill req hit", req_hit, 1'b1);
    tb_check64("fill req data", req_data, 64'h0011_2233_4455_6677);
    tb_check1("fill walk hit", walk_hit, 1'b1);
    tb_check64("fill walk data", walk_data, 64'h0011_2233_4455_6677);

    commit_store(WORD0, 64'haabb_ccdd_eeff_1234, 8'b1010_0101, 1'b0);
    req_lookup_addr = WORD0;
    #1;
    tb_check1("partial store hit remains valid", req_hit, 1'b1);
    tb_check64("partial store byte merge", req_data,
               64'haa11_cc33_44ff_6634);

    commit_store(WORD1, 64'hdead_beef_cafe_babe, 8'b1111_1111, 1'b0);
    req_lookup_addr = WORD1;
    #1;
    // 【line-dcache】write-no-allocate: full-8B store miss 也不建行
    tb_check1("full store miss no allocate (line model)", req_hit, 1'b0);

    commit_store(WORD2, 64'h5555_6666_7777_8888, 8'b0000_1111, 1'b0);
    req_lookup_addr = WORD2;
    #1;
    tb_check1("partial store miss no allocate", req_hit, 1'b0);

    req_lookup_addr = MMIO_WORD;
    walk_lookup_addr = MMIO_WORD;
    #1;
    tb_check1("mmio req not cacheable", req_cacheable, 1'b0);
    tb_check1("mmio walk not cacheable", walk_cacheable, 1'b0);
    tb_check1("mmio req miss", req_hit, 1'b0);

    req_lookup_addr = WORD0;
    commit_store(MMIO_WORD, 64'hffff_ffff_ffff_ffff, 8'b1111_1111, 1'b1);
    #1;
    tb_check1("invalidate all clears old word", req_hit, 1'b0);

    tb_finish("tb_ooo_data_word_cache");
  end
endmodule
