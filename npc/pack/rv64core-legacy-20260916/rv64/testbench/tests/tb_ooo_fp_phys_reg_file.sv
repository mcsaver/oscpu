`include "define.v"

// T3H：FP 物理寄存器堆的四个读口统一只读取已在上升沿落账的
// regs_q。这与 FpIQ/IntIQ 对 FP wake 的 sticky-only 发射边界成对，
// 用时序边界切断 completion -> PRF -> execute/store 的同拍组合锥。
module tb_ooo_fp_phys_reg_file;
  `include "tb_common.svh"

  localparam PHY_REG_ADDR_W = 6;

  reg clk;
  reg rst;
  reg recover;
  reg [`XLEN * `REG_NUM - 1:0] recover_fprs;
  reg [PHY_REG_ADDR_W-1:0] read0_addr;
  wire [`XLEN-1:0] read0_data;
  reg [PHY_REG_ADDR_W-1:0] read1_addr;
  wire [`XLEN-1:0] read1_data;
  reg [PHY_REG_ADDR_W-1:0] read2_addr;
  wire [`XLEN-1:0] read2_data;
  reg [PHY_REG_ADDR_W-1:0] read3_addr;
  wire [`XLEN-1:0] read3_data;
  reg write0_valid;
  reg [PHY_REG_ADDR_W-1:0] write0_addr;
  reg [`XLEN-1:0] write0_data;
  reg write1_valid;
  reg [PHY_REG_ADDR_W-1:0] write1_addr;
  reg [`XLEN-1:0] write1_data;

  OooFpPhysRegFile dut (
    .clk(clk),
    .rst(rst),
    .recover_i(recover),
    .recover_fprs_i(recover_fprs),
    .read0_addr_i(read0_addr),
    .read0_data_o(read0_data),
    .read1_addr_i(read1_addr),
    .read1_data_o(read1_data),
    .read2_addr_i(read2_addr),
    .read2_data_o(read2_data),
    .read3_addr_i(read3_addr),
    .read3_data_o(read3_data),
    .write0_valid_i(write0_valid),
    .write0_addr_i(write0_addr),
    .write0_data_i(write0_data),
    .write1_valid_i(write1_valid),
    .write1_addr_i(write1_addr),
    .write1_data_i(write1_data)
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

  task automatic clear_inputs;
    begin
      recover = 1'b0;
      recover_fprs = {(`XLEN * `REG_NUM){1'b0}};
      read0_addr = {PHY_REG_ADDR_W{1'b0}};
      read1_addr = {PHY_REG_ADDR_W{1'b0}};
      read2_addr = {PHY_REG_ADDR_W{1'b0}};
      read3_addr = {PHY_REG_ADDR_W{1'b0}};
      write0_valid = 1'b0;
      write0_addr = {PHY_REG_ADDR_W{1'b0}};
      write0_data = {`XLEN{1'b0}};
      write1_valid = 1'b0;
      write1_addr = {PHY_REG_ADDR_W{1'b0}};
      write1_data = {`XLEN{1'b0}};
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

  task automatic set_all_reads;
    input [PHY_REG_ADDR_W-1:0] addr;
    begin
      read0_addr = addr;
      read1_addr = addr;
      read2_addr = addr;
      read3_addr = addr;
    end
  endtask

  task automatic check_all_reads;
    input [1023:0] phase;
    input [`XLEN-1:0] exp;
    begin
      tb_check64({phase, " read0"}, read0_data, exp);
      tb_check64({phase, " read1"}, read1_data, exp);
      tb_check64({phase, " read2"}, read2_data, exp);
      tb_check64({phase, " read3"}, read3_data, exp);
    end
  endtask

  initial begin
    tb_errors = 0;
    reset_dut();

`ifdef FP_PRF_STORED_NEGATIVE
    // 未加断言的 RED 模板：先使自然读视图与 regs_q 一致，再只
    // force 一个读口跨过断言沿。RTL 后续加 sticky/store-only 断言时，
    // 该宏应精确命中新 marker。
    write0_valid = 1'b1;
    write0_addr = 6'd33;
    write0_data = 64'h3333_3333_0000_0021;
    `TB_TICK(clk);
    clear_inputs();
    set_all_reads(6'd33);
    #1;
    tb_check64("FP PRF negative starts natural", read0_data, dut.regs_q[33]);
    $display("[FP-PRF-STORED-NEGATIVE] force read0 across assertion edge");
    force dut.read0_data_o = 64'hdead_beef_0000_0021;
    `TB_TICK(clk);
    release dut.read0_data_o;
    $display("[FP-PRF-STORED-NEGATIVE] completed one assertion edge");
    $finish_and_return(0);
`endif

    // phase 1: write0 命中 p33。N 拍四口必须仍观察 old，N+1 才观察 new。
    write0_valid = 1'b1;
    write0_addr = 6'd33;
    write0_data = 64'h3333_3333_0000_0021;
    `TB_TICK(clk);
    clear_inputs();
    set_all_reads(6'd33);
    #1;
    check_all_reads("T3H p33 seed", 64'h3333_3333_0000_0021);

    write0_valid = 1'b1;
    write0_addr = 6'd33;
    write0_data = 64'haaaa_aaaa_0000_0021;
    #1;
    $display("[T3H-RED-OBS] write0 p33 N reads={%016x,%016x,%016x,%016x}",
             read0_data, read1_data, read2_data, read3_data);
    check_all_reads("T3H write0 N keeps old", 64'h3333_3333_0000_0021);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    #1;
    check_all_reads("T3H write0 N+1 sees new", 64'haaaa_aaaa_0000_0021);
    $display("[T3H-COVERAGE-OBS] write0 p33 N+1 stored=%016x", read0_data);

    // phase 2: write1(FP load) 也不再对 store 读口例外旁路；四口合同一致。
    write1_valid = 1'b1;
    write1_addr = 6'd34;
    write1_data = 64'h3434_3434_0000_0022;
    `TB_TICK(clk);
    clear_inputs();
    set_all_reads(6'd34);
    #1;
    check_all_reads("T3H p34 seed", 64'h3434_3434_0000_0022);

    write1_valid = 1'b1;
    write1_addr = 6'd34;
    write1_data = 64'hbbbb_bbbb_0000_0022;
    #1;
    $display("[T3H-RED-OBS] write1 p34 N reads={%016x,%016x,%016x,%016x}",
             read0_data, read1_data, read2_data, read3_data);
    check_all_reads("T3H write1 N keeps old", 64'h3434_3434_0000_0022);
    `TB_TICK(clk);
    write1_valid = 1'b0;
    #1;
    check_all_reads("T3H write1 N+1 sees new", 64'hbbbb_bbbb_0000_0022);
    $display("[T3H-COVERAGE-OBS] write1 p34 N+1 stored=%016x", read3_data);

    // 双写同址的存储优先级仍为 write1 > write0，但优先级只在 N 沿
    // 落账，不能重新变成当拍读口旁路。
    write0_valid = 1'b1;
    write0_addr = 6'd35;
    write0_data = 64'h3535_3535_0000_0023;
    `TB_TICK(clk);
    clear_inputs();
    set_all_reads(6'd35);
    write0_valid = 1'b1;
    write0_addr = 6'd35;
    write0_data = 64'hcccc_cccc_0000_0023;
    write1_valid = 1'b1;
    write1_addr = 6'd35;
    write1_data = 64'hdddd_dddd_0000_0023;
    #1;
    check_all_reads("T3H collision N keeps old", 64'h3535_3535_0000_0023);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    write1_valid = 1'b0;
    #1;
    check_all_reads("T3H collision N+1 write1 wins", 64'hdddd_dddd_0000_0023);
    $display("[T3H-COVERAGE-OBS] collision N+1 write1-wins=%016x", read0_data);

    // preg0 是真 FPR：可写、可读，也遵守同一拍边界，不存在 x0 特判。
    clear_inputs();
    set_all_reads(6'd0);
    write0_valid = 1'b1;
    write0_addr = 6'd0;
    write0_data = 64'h0000_0000_0000_f000;
    #1;
    check_all_reads("T3H preg0 N keeps reset value", 64'h0);
    `TB_TICK(clk);
    write0_valid = 1'b0;
    #1;
    check_all_reads("T3H preg0 N+1 is writable", 64'h0000_0000_0000_f000);
    $display("[T3H-COVERAGE-OBS] preg0 N+1 stored=%016x", read0_data);

    // recover 在一个沿上覆盖普通写：低 32 项拷贝 committed FPR，高项清零。
    clear_inputs();
    recover = 1'b1;
    recover_fprs[0 * `XLEN +: `XLEN] = 64'h1111_0000_0000_0000;
    recover_fprs[31 * `XLEN +: `XLEN] = 64'h3131_0000_0000_001f;
    write1_valid = 1'b1;
    write1_addr = 6'd0;
    write1_data = 64'hffff_ffff_ffff_ffff;
    `TB_TICK(clk);
    clear_inputs();
    read0_addr = 6'd0;
    read1_addr = 6'd31;
    read2_addr = 6'd33;
    #1;
    tb_check64("T3H recover restores preg0", read0_data,
               64'h1111_0000_0000_0000);
    tb_check64("T3H recover restores preg31", read1_data,
               64'h3131_0000_0000_001f);
    tb_check64("T3H recover clears high preg", read2_data, 64'h0);
    $display("[T3H-COVERAGE-OBS] recover p0=%016x p31=%016x p33=%016x",
             read0_data, read1_data, read2_data);

    tb_finish("tb_ooo_fp_phys_reg_file");
  end
endmodule
