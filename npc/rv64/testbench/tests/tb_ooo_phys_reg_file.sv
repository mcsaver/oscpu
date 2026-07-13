`include "define.v"

module tb_ooo_phys_reg_file;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg [PHY_REG_ADDR_W-1:0] read0_addr;
  wire [`XLEN-1:0] read0_data;
  reg [PHY_REG_ADDR_W-1:0] read1_addr;
  wire [`XLEN-1:0] read1_data;
  reg [PHY_REG_ADDR_W-1:0] read2_addr;
  wire [`XLEN-1:0] read2_data;
  reg [PHY_REG_ADDR_W-1:0] read3_addr;
  wire [`XLEN-1:0] read3_data;
  reg [PHY_REG_ADDR_W-1:0] read8_addr;
  wire [`XLEN-1:0] read8_data;
  reg bypass0_valid;
  reg [PHY_REG_ADDR_W-1:0] bypass0_addr;
  reg [`XLEN-1:0] bypass0_data;
  reg bypass1_valid;
  reg [PHY_REG_ADDR_W-1:0] bypass1_addr;
  reg [`XLEN-1:0] bypass1_data;
  reg write0_valid;
  reg [PHY_REG_ADDR_W-1:0] write0_addr;
  reg [`XLEN-1:0] write0_data;
  reg write1_valid;
  reg [PHY_REG_ADDR_W-1:0] write1_addr;
  reg [`XLEN-1:0] write1_data;

  OooPhysRegFile dut (
    .clk(clk),
    .rst(rst),
    .recover_i(1'b0),
    .recover_gprs_i({(`XLEN * `REG_NUM){1'b0}}),
    .read0_addr_i(read0_addr),
    .read0_data_o(read0_data),
    .read1_addr_i(read1_addr),
    .read1_data_o(read1_data),
    .read2_addr_i(read2_addr),
    .read2_data_o(read2_data),
    .read3_addr_i(read3_addr),
    .read3_data_o(read3_data),
    .read8_addr_i(read8_addr),
    .read8_data_o(read8_data),
    .bypass0_valid_i(bypass0_valid),
    .bypass0_addr_i(bypass0_addr),
    .bypass0_data_i(bypass0_data),
    .bypass1_valid_i(bypass1_valid),
    .bypass1_addr_i(bypass1_addr),
    .bypass1_data_i(bypass1_data),
    .write0_valid_i(write0_valid),
    .write0_addr_i(write0_addr),
    .write0_data_i(write0_data),
    .write1_valid_i(write1_valid),
    .write1_addr_i(write1_addr),
    .write1_data_i(write1_data)
  );

  task automatic clear_inputs;
    begin
      read0_addr = 6'd0;
      read1_addr = 6'd0;
      read2_addr = 6'd0;
      read3_addr = 6'd0;
      read8_addr = 6'd0;
      bypass0_valid = 1'b0;
      bypass0_addr = 6'd0;
      bypass0_data = 32'h0;
      bypass1_valid = 1'b0;
      bypass1_addr = 6'd0;
      bypass1_data = 32'h0;
      write0_valid = 1'b0;
      write0_addr = 6'd0;
      write0_data = 32'h0;
      write1_valid = 1'b0;
      write1_addr = 6'd0;
      write1_data = 32'h0;
    end
  endtask

  task automatic reset_dut;
    begin
      clk = 1'b0;
      rst = 1'b1;
      clear_inputs();
      `TB_TICK(clk);
      rst = 1'b0;
      #1;
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

    read0_addr = 6'd1;
    read1_addr = 6'd0;
    #1;
    tb_check32("reset p1 zero", read0_data, 32'h0);
    tb_check32("p0 zero", read1_data, 32'h0);

    write0_valid = 1'b1;
    write0_addr = 6'd1;
    write0_data = 32'h1111_0001;
    bypass0_valid = 1'b1;
    bypass0_addr = 6'd1;
    bypass0_data = 32'h1111_0001;
    write1_valid = 1'b1;
    write1_addr = 6'd2;
    write1_data = 32'h2222_0002;
    bypass1_valid = 1'b1;
    bypass1_addr = 6'd2;
    bypass1_data = 32'h2222_0002;
    read0_addr = 6'd1;
    read1_addr = 6'd2;
    read2_addr = 6'd1;
    read3_addr = 6'd2;
    read8_addr = 6'd1;
    #1;
    tb_check32("explicit fast lane0 read0", read0_data, 32'h1111_0001);
    tb_check32("explicit fast lane1 read1", read1_data, 32'h2222_0002);
    tb_check32("explicit fast lane0 read2", read2_data, 32'h1111_0001);
    tb_check32("explicit fast lane1 read3", read3_data, 32'h2222_0002);
    tb_check32("T3F initial read8 ignores fast lane0 bypass",
               read8_data, 32'h0);
    `TB_TICK(clk);
    clear_inputs();

    read0_addr = 6'd1;
    read1_addr = 6'd2;
    #1;
    tb_check32("stored p1", read0_data, 32'h1111_0001);
    tb_check32("stored p2", read1_data, 32'h2222_0002);

    // T3F RED：全部五个读口只观察上一个时钟边沿落下的 full-write。
    // read0-3 与 read8 只允许显式 fast bypass 同拍可见；当前 read8 的
    // full write-through 必须在下列 full-only 场景稳定变红。
    write0_valid = 1'b1;
    write0_addr = 6'd1;
    write0_data = 32'h1111_1001;
    write1_valid = 1'b1;
    write1_addr = 6'd2;
    write1_data = 32'h2222_2002;
    read0_addr = 6'd1;
    read1_addr = 6'd2;
    read2_addr = 6'd1;
    read3_addr = 6'd2;
    read8_addr = 6'd1;
    #1;
    tb_check32("PRF-FULL-WRITE-DELAY N read0 keeps old",
               read0_data, 32'h1111_0001);
    tb_check32("PRF-FULL-WRITE-DELAY N read1 keeps old",
               read1_data, 32'h2222_0002);
    tb_check32("PRF-FULL-WRITE-DELAY N read2 keeps old",
               read2_data, 32'h1111_0001);
    tb_check32("PRF-FULL-WRITE-DELAY N read3 keeps old",
               read3_data, 32'h2222_0002);
    tb_check32("T3F PRF-FULL-WRITE-DELAY N read8 keeps old",
               read8_data, 32'h1111_0001);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
    #1;
    tb_check32("PRF-FULL-WRITE-DELAY N+1 read0 sees new",
               read0_data, 32'h1111_1001);
    tb_check32("PRF-FULL-WRITE-DELAY N+1 read1 sees new",
               read1_data, 32'h2222_2002);
    tb_check32("PRF-FULL-WRITE-DELAY N+1 read2 sees new",
               read2_data, 32'h1111_1001);
    tb_check32("PRF-FULL-WRITE-DELAY N+1 read3 sees new",
               read3_data, 32'h2222_2002);
    tb_check32("T3F PRF-FULL-WRITE-DELAY N+1 read8 sees new",
               read8_data, 32'h1111_1001);

    // 先建立非零旧值，再验证双写同址时所有读口在上升沿前
    // 保持旧值、上升沿后才统一看到 write1 的新值。
    write0_valid = 1'b1;
    write0_addr = 6'd3;
    write0_data = 32'h3333_0003;
    `TB_TICK(clk);
    write0_valid = 1'b0;

    write0_valid = 1'b1;
    write0_addr = 6'd3;
    write0_data = 32'haaaa_0003;
    write1_valid = 1'b1;
    write1_addr = 6'd3;
    write1_data = 32'hbbbb_0003;
    read0_addr = 6'd3;
    read1_addr = 6'd3;
    read2_addr = 6'd3;
    read3_addr = 6'd3;
    read8_addr = 6'd3;
    #1;
    tb_check32("PRF-FULL-WRITE-DELAY collision N read0 keeps old",
               read0_data, 32'h3333_0003);
    tb_check32("PRF-FULL-WRITE-DELAY collision N read1 keeps old",
               read1_data, 32'h3333_0003);
    tb_check32("PRF-FULL-WRITE-DELAY collision N read2 keeps old",
               read2_data, 32'h3333_0003);
    tb_check32("PRF-FULL-WRITE-DELAY collision N read3 keeps old",
               read3_data, 32'h3333_0003);
    tb_check32("T3F PRF-FULL-WRITE-DELAY collision N read8 keeps old",
               read8_data, 32'h3333_0003);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
    #1;
    tb_check32("PRF-FULL-WRITE-DELAY collision N+1 read0 sees new",
               read0_data, 32'hbbbb_0003);
    tb_check32("PRF-FULL-WRITE-DELAY collision N+1 read1 sees new",
               read1_data, 32'hbbbb_0003);
    tb_check32("PRF-FULL-WRITE-DELAY collision N+1 read2 sees new",
               read2_data, 32'hbbbb_0003);
    tb_check32("PRF-FULL-WRITE-DELAY collision N+1 read3 sees new",
               read3_data, 32'hbbbb_0003);
    tb_check32("T3F PRF-FULL-WRITE-DELAY collision N+1 read8 sees new",
               read8_data, 32'hbbbb_0003);

    clear_inputs();
    write0_valid = 1'b1;
    write0_addr = 6'd3;
    write0_data = 32'hcccc_0003;
    bypass0_valid = 1'b1;
    bypass0_addr = 6'd3;
    bypass0_data = 32'hcccc_0003;
    write1_valid = 1'b1;
    write1_addr = 6'd3;
    write1_data = 32'hdddd_0003;
    bypass1_valid = 1'b1;
    bypass1_addr = 6'd3;
    bypass1_data = 32'hdddd_0003;
    read0_addr = 6'd3;
    read1_addr = 6'd3;
    read2_addr = 6'd3;
    read3_addr = 6'd3;
    read8_addr = 6'd3;
    #1;
    tb_check32("fast collision read0 lane1 priority",
               read0_data, 32'hdddd_0003);
    tb_check32("fast collision read1 lane1 priority",
               read1_data, 32'hdddd_0003);
    tb_check32("fast collision read2 lane1 priority",
               read2_data, 32'hdddd_0003);
    tb_check32("fast collision read3 lane1 priority",
               read3_data, 32'hdddd_0003);
    tb_check32("T3F fast collision read8 keeps stored value",
               read8_data, 32'hbbbb_0003);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
    bypass0_valid = 1'b0;
    bypass1_valid = 1'b0;
    #1;
    tb_check32("fast collision stored lane1 value",
               read0_data, 32'hdddd_0003);
    tb_check32("T3F fast collision N+1 read8 sees stored lane1 value",
               read8_data, 32'hdddd_0003);

    // mixed：lane0 进入 fast 子集，lane1 只有 full write。所有读口必须只让
    // lane0 同拍可见；read8 对 full-only lane1 也要等到 N+1。
    clear_inputs();
    write0_valid = 1'b1;
    write0_addr = 6'd4;
    write0_data = 32'h4444_0004;
    bypass0_valid = 1'b1;
    bypass0_addr = 6'd4;
    bypass0_data = 32'h4444_0004;
    write1_valid = 1'b1;
    write1_addr = 6'd5;
    write1_data = 32'h5555_0005;
    read0_addr = 6'd4;
    read1_addr = 6'd5;
    read2_addr = 6'd4;
    read3_addr = 6'd5;
    read8_addr = 6'd5;
    #1;
    tb_check32("mixed fast lane0 read0 sees new",
               read0_data, 32'h4444_0004);
    tb_check32("mixed full-only lane1 read1 keeps old",
               read1_data, 32'h0);
    tb_check32("mixed fast lane0 read2 sees new",
               read2_data, 32'h4444_0004);
    tb_check32("mixed full-only lane1 read3 keeps old",
               read3_data, 32'h0);
    tb_check32("T3F mixed full-only lane1 read8 keeps old",
               read8_data, 32'h0);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
    bypass0_valid = 1'b0;
    #1;
    tb_check32("mixed N+1 read0 sees stored lane0",
               read0_data, 32'h4444_0004);
    tb_check32("mixed N+1 read1 sees stored lane1",
               read1_data, 32'h5555_0005);
    tb_check32("mixed N+1 read2 sees stored lane0",
               read2_data, 32'h4444_0004);
    tb_check32("mixed N+1 read3 sees stored lane1",
               read3_data, 32'h5555_0005);
    tb_check32("T3F mixed N+1 read8 sees stored lane1",
               read8_data, 32'h5555_0005);

    // XLEN=64 高半 directed：证明 read8 stored-only 合同不是仅在低 32 位成立。
    clear_inputs();
    write0_valid = 1'b1;
    write0_addr = 6'd9;
    write0_data = 64'h89ab_cdef_0123_4567;
    read8_addr = 6'd9;
    #1;
    tb_check32("T3F read8 64b N high keeps old", read8_data[63:32], 32'h0);
    tb_check32("T3F read8 64b N low keeps old", read8_data[31:0], 32'h0);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    #1;
    tb_check32("T3F read8 64b N+1 high sees stored",
               read8_data[63:32], 32'h89ab_cdef);
    tb_check32("T3F read8 64b N+1 low sees stored",
               read8_data[31:0], 32'h0123_4567);

    clear_inputs();
    write0_valid = 1'b1;
    write0_addr = 6'd0;
    write0_data = 32'hffff_ffff;
    bypass0_valid = 1'b1;
    bypass0_addr = 6'd0;
    bypass0_data = 32'hffff_ffff;
    write1_valid = 1'b1;
    write1_addr = 6'd0;
    write1_data = 32'heeee_eeee;
    bypass1_valid = 1'b1;
    bypass1_addr = 6'd0;
    bypass1_data = 32'heeee_eeee;
    read0_addr = 6'd0;
    read1_addr = 6'd0;
    read2_addr = 6'd0;
    read3_addr = 6'd0;
    read8_addr = 6'd0;
    #1;
    tb_check32("p0 read0 ignores fast/full write", read0_data, 32'h0);
    tb_check32("p0 read1 ignores fast/full write", read1_data, 32'h0);
    tb_check32("p0 read2 ignores fast/full write", read2_data, 32'h0);
    tb_check32("p0 read3 ignores fast/full write", read3_data, 32'h0);
    tb_check32("p0 read8 ignores full write", read8_data, 32'h0);
    `TB_TICK(clk);
    clear_inputs();
    read0_addr = 6'd0;
    #1;
    tb_check32("p0 ignores write", read0_data, 32'h0);

`ifdef PRF_FAST_WB_SUBSET_NEGATIVE
    // 仅供断言非真空验证：两个 fast lane 的 data 均与同 lane
    // full write 不同，两条断言必须各自触发 marker。
    clear_inputs();
    write0_valid = 1'b1;
    write0_addr = 6'd6;
    write0_data = 32'h6666_0006;
    bypass0_valid = 1'b1;
    bypass0_addr = 6'd6;
    bypass0_data = 32'hdead_0006;
    write1_valid = 1'b1;
    write1_addr = 6'd7;
    write1_data = 32'h7777_0007;
    bypass1_valid = 1'b1;
    bypass1_addr = 6'd7;
    bypass1_data = 32'hdead_0007;
    `TB_TICK(clk);
`endif

`ifdef PRF_READ8_STORED_NEGATIVE
    // 仅供 T3F 断言非真空验证：自然状态下 read8 与 regs_q 相等，
    // 之后强制输出跨过一个断言沿，必须精准触发 stored-only marker。
    clear_inputs();
    read8_addr = 6'd8;
    #1;
    tb_check32("PRF read8 stored negative starts natural",
               read8_data, dut.regs_q[8]);
    $display("[PRF-READ8-STORED-NEGATIVE] force read8 across assertion edge");
    force dut.read8_data_o = 32'hdead_0008;
    `TB_TICK(clk);
    release dut.read8_data_o;
    $display("[PRF-READ8-STORED-NEGATIVE] completed one assertion edge");
`endif

    tb_finish("tb_ooo_phys_reg_file");
  end
endmodule
