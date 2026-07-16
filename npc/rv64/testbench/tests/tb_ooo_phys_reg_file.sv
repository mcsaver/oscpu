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
    write1_valid = 1'b1;
    write1_addr = 6'd2;
    write1_data = 32'h2222_0002;
    read0_addr = 6'd1;
    read1_addr = 6'd2;
    read2_addr = 6'd1;
    read3_addr = 6'd2;
    read8_addr = 6'd1;
    #1;
    tb_check32("T3M initial write N read0 keeps old", read0_data, 32'h0);
    tb_check32("T3M initial write N read1 keeps old", read1_data, 32'h0);
    tb_check32("T3M initial write N read2 keeps old", read2_data, 32'h0);
    tb_check32("T3M initial write N read3 keeps old", read3_data, 32'h0);
    tb_check32("T3M initial write N read8 keeps old", read8_data, 32'h0);
    `TB_TICK(clk);
    clear_inputs();

    read0_addr = 6'd1;
    read1_addr = 6'd2;
    #1;
    tb_check32("stored p1", read0_data, 32'h1111_0001);
    tb_check32("stored p2", read1_data, 32'h2222_0002);

    // T3M RED：全部五个读口只观察上一个时钟边沿落下的 full-write。
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
    write1_valid = 1'b1;
    write1_addr = 6'd3;
    write1_data = 32'hdddd_0003;
    read0_addr = 6'd3;
    read1_addr = 6'd3;
    read2_addr = 6'd3;
    read3_addr = 6'd3;
    read8_addr = 6'd3;
    #1;
    tb_check32("T3M collision N read0 keeps stored value",
               read0_data, 32'hbbbb_0003);
    tb_check32("T3M collision N read1 keeps stored value",
               read1_data, 32'hbbbb_0003);
    tb_check32("T3M collision N read2 keeps stored value",
               read2_data, 32'hbbbb_0003);
    tb_check32("T3M collision N read3 keeps stored value",
               read3_data, 32'hbbbb_0003);
    tb_check32("T3M collision N read8 keeps stored value",
               read8_data, 32'hbbbb_0003);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
    #1;
    tb_check32("collision stored lane1 value",
               read0_data, 32'hdddd_0003);
    tb_check32("T3M collision N+1 read8 sees stored lane1 value",
               read8_data, 32'hdddd_0003);

    // mixed：两个正式写口同拍写不同地址，所有读口都等到 N+1。
    clear_inputs();
    write0_valid = 1'b1;
    write0_addr = 6'd4;
    write0_data = 32'h4444_0004;
    write1_valid = 1'b1;
    write1_addr = 6'd5;
    write1_data = 32'h5555_0005;
    read0_addr = 6'd4;
    read1_addr = 6'd5;
    read2_addr = 6'd4;
    read3_addr = 6'd5;
    read8_addr = 6'd5;
    #1;
    tb_check32("T3M mixed lane0 read0 keeps old",
               read0_data, 32'h0);
    tb_check32("mixed full-only lane1 read1 keeps old",
               read1_data, 32'h0);
    tb_check32("T3M mixed lane0 read2 keeps old",
               read2_data, 32'h0);
    tb_check32("mixed full-only lane1 read3 keeps old",
               read3_data, 32'h0);
    tb_check32("T3F mixed full-only lane1 read8 keeps old",
               read8_data, 32'h0);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
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
    write1_valid = 1'b1;
    write1_addr = 6'd0;
    write1_data = 32'heeee_eeee;
    read0_addr = 6'd0;
    read1_addr = 6'd0;
    read2_addr = 6'd0;
    read3_addr = 6'd0;
    read8_addr = 6'd0;
    #1;
    tb_check32("p0 read0 ignores full write", read0_data, 32'h0);
    tb_check32("p0 read1 ignores full write", read1_data, 32'h0);
    tb_check32("p0 read2 ignores full write", read2_data, 32'h0);
    tb_check32("p0 read3 ignores full write", read3_data, 32'h0);
    tb_check32("p0 read8 ignores full write", read8_data, 32'h0);
    `TB_TICK(clk);
    clear_inputs();
    read0_addr = 6'd0;
    #1;
    tb_check32("p0 ignores write", read0_data, 32'h0);

`ifdef PRF_INT_READ_STORED_NEGATIVE
    // 仅供 T3M 断言非真空验证：自然状态下 read0 与 regs_q 相等，
    // 之后强制输出跨过一个断言沿，必须精准触发统一 stored-only marker。
    clear_inputs();
    read0_addr = 6'd8;
    #1;
    tb_check32("PRF integer stored negative starts natural",
               read0_data, dut.regs_q[8]);
    $display("[PRF-INT-READ-STORED-NEGATIVE] force read0 across assertion edge");
    force dut.read0_data_o = 32'hdead_0008;
    `TB_TICK(clk);
    release dut.read0_data_o;
    $display("[PRF-INT-READ-STORED-NEGATIVE] completed one assertion edge");
`endif

    tb_finish("tb_ooo_phys_reg_file");
  end
endmodule
